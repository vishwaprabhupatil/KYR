from __future__ import annotations

import base64
import json
import os
import re
import threading
import tempfile
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Literal

import sys

from fastapi import Body, FastAPI, File, Form, HTTPException, Request, UploadFile
from fastapi.responses import Response
from fastapi.middleware.cors import CORSMiddleware
import google.generativeai as genai
from llama_cpp import Llama
from llama_cpp.llama_grammar import LlamaGrammar
from PIL import Image
from pydantic import BaseModel, Field
from pypdf import PdfReader
import pytesseract
from gtts import gTTS
from gtts.tts import gTTSError
import hashlib


UPLOAD_DIR = Path(__file__).parent / "uploads"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

LLM_LOCK = threading.Lock()
LLM: Llama | None = None
ANALYSIS_GRAMMAR: LlamaGrammar | None = None
GEMINI_MODEL_NAME = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
GEMINI_READY = False

# Small in-memory cache for TTS audio (avoid repeated gTTS calls).
TTS_CACHE: dict[str, bytes] = {}
TTS_CACHE_LOCK = threading.Lock()
TTS_CACHE_MAX_ITEMS = int(os.getenv("TTS_CACHE_MAX_ITEMS", "64"))

ANALYSIS_JSON_SCHEMA: dict[str, Any] = {
  "type": "object",
  "additionalProperties": False,
  "required": [
    "safety_score",
    "risk_level",
    "clauses",
    "risk_alerts",
    "translated_text",
    "simplified_explanation",
  ],
  "properties": {
    "safety_score": {"type": "number"},
    "risk_level": {"type": "string", "enum": ["Low", "Medium", "High"]},
    "clauses": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": False,
        "required": ["title", "summary", "severity"],
        "properties": {
          "title": {"type": "string"},
          "summary": {"type": "string"},
          "severity": {"type": "string", "enum": ["Low", "Medium", "High"]},
        },
      },
    },
    "risk_alerts": {"type": "array", "items": {"type": "string"}},
    "translated_text": {"type": "string"},
    "simplified_explanation": {"type": "string"},
  },
}


def _env(name: str) -> str:
  val = os.getenv(name, "").strip()
  if not val:
    raise RuntimeError(f"Missing environment variable: {name}")
  return val


def _env_optional(name: str) -> str | None:
  val = os.getenv(name, "").strip()
  return val or None


def _guess_mime(filename: str) -> str:
  ext = filename.lower().split(".")[-1]
  if ext == "pdf":
    return "application/pdf"
  if ext == "png":
    return "image/png"
  if ext in ("jpg", "jpeg"):
    return "image/jpeg"
  return "application/octet-stream"


def _analysis_prompt(language: str) -> str:
  return (
    "You are KYY (Know Your Rights), an assistant for rural India.\n"
    "You will be given extracted text from a legal document.\n\n"
    "Task:\n"
    f"1) Explain it in simple {language} (very easy words).\n"
    f"2) Write a DETAILED summary in {language}.\n"
    f"3) Identify risky clauses and risk alerts in {language}.\n"
    "4) Provide a contract safety score (0-100) and risk level (Low/Medium/High).\n\n"
    "Return ONLY valid JSON (no markdown, no extra text) with exactly these keys:\n"
    "{\n"
    '  "safety_score": number,\n'
    '  "risk_level": "Low" | "Medium" | "High",\n'
    '  "clauses": [{"title": string, "summary": string, "severity": "Low" | "Medium" | "High"}],\n'
    '  "risk_alerts": [string],\n'
    '  "translated_text": string,\n'
    '  "simplified_explanation": string\n'
    "}\n\n"
    "Rules:\n"
    "- If the text is incomplete/unclear, mention it in risk_alerts.\n"
    f"- ALL human-readable strings MUST be in {language} and use the native script.\n"
    "- Do NOT answer in English unless the selected language is English.\n"
    f"- simplified_explanation MUST be in {language}.\n"
    f"- clause summaries and risk_alerts MUST be in {language}.\n"
    "- translated_text can be an empty string if you are not confident.\n"
    "- simplified_explanation should be detailed and structured (use \\n newlines):\n"
    "  - What this document is about\n"
    "  - Who are the parties\n"
    "  - Money/payment amounts and due dates (if any)\n"
    "  - Duration/renewal\n"
    "  - Key obligations (your duties vs other party duties)\n"
    "  - Termination/cancellation\n"
    "  - Penalties/fees/interest\n"
    "  - Dispute resolution/jurisdiction\n"
    "  - What you should do next (action steps)\n"
    "  - Risks/alerts section (include risk_alerts content)\n"
    "- Aim for ~12–25 lines of explanation.\n"
  )


def _extract_json(text: str) -> str:
  t = (text or "").strip()
  m = re.search(r"\{[\s\S]*\}", t)
  if not m:
    raise ValueError(f"Could not find JSON in model response: {t[:2000]}")
  return m.group(0)


def _escape_control_chars_in_json_strings(raw_json: str) -> str:
  """
  llama.cpp can emit literal newlines/control chars inside JSON strings, which
  makes Python's json.loads fail. This sanitizes ONLY characters inside strings.
  """
  s = raw_json
  out: list[str] = []
  in_string = False
  escaped = False
  for ch in s:
    code = ord(ch)
    if in_string:
      if escaped:
        out.append(ch)
        escaped = False
        continue
      if ch == "\\":
        out.append(ch)
        escaped = True
        continue
      if ch == '"':
        out.append(ch)
        in_string = False
        continue
      if code < 0x20:
        if ch == "\n":
          out.append("\\n")
        elif ch == "\r":
          out.append("\\r")
        elif ch == "\t":
          out.append("\\t")
        else:
          out.append(f"\\u{code:04x}")
        continue
      out.append(ch)
      continue
    else:
      out.append(ch)
      if ch == '"':
        in_string = True
        escaped = False
  return "".join(out)


def _extract_text(file_path: Path, mime: str) -> str:
  if mime == "application/pdf":
    reader = PdfReader(str(file_path))
    parts: list[str] = []
    for page in reader.pages:
      parts.append(page.extract_text() or "")
    return "\n\n".join(p for p in parts if p.strip()).strip()

  if mime.startswith("image/"):
    with Image.open(file_path) as img:
      img = img.convert("RGB")
      return (pytesseract.image_to_string(img) or "").strip()

  return ""


def _tesseract_lang(selected_language: str) -> str:
  # Prefer script-specific OCR. Fallback to English for unknown.
  l = (selected_language or "").strip().lower()
  return {
    "hindi": "hin",
    "kannada": "kan",
    "marathi": "mar",
    "tamil": "tam",
    "telugu": "tel",
    "bengali": "ben",
  }.get(l, "eng")


def _extract_text_with_language(file_path: Path, mime: str, language: str) -> str:
  if mime == "application/pdf":
    return _extract_text(file_path, mime)
  if mime.startswith("image/"):
    with Image.open(file_path) as img:
      img = _preprocess_for_ocr(img)
      lang = _tesseract_lang(language)
      # Combine with English as a fallback for mixed docs.
      lang_combo = f"{lang}+eng" if lang != "eng" else "eng"
      config = "--oem 1 --psm 6"
      return (pytesseract.image_to_string(img, lang=lang_combo, config=config) or "").strip()
  return ""


def _preprocess_for_ocr(img: Image.Image) -> Image.Image:
  """
  Lightweight OCR preprocessing to improve accuracy on mobile photos.
  """
  from PIL import ImageEnhance, ImageOps, ImageFilter

  img = img.convert("RGB")
  # Upscale small images
  if max(img.size) < 1600:
    scale = 2
    img = img.resize((img.size[0] * scale, img.size[1] * scale))

  img = ImageOps.grayscale(img)
  img = ImageOps.autocontrast(img)

  # Slight sharpening helps text edges
  img = img.filter(ImageFilter.UnsharpMask(radius=2, percent=150, threshold=3))

  # Increase contrast
  img = ImageEnhance.Contrast(img).enhance(1.6)
  return img


def _llm() -> Llama:
  if LLM is None:
    raise RuntimeError("LLM not initialized. Set LLAMA_MODEL_PATH and restart server.")
  return LLM


def _analysis_grammar() -> LlamaGrammar:
  if ANALYSIS_GRAMMAR is None:
    raise RuntimeError("Analysis grammar not initialized.")
  return ANALYSIS_GRAMMAR


@dataclass
class DocStore:
  file_path: Path
  filename: str
  language: str
  mime: str
  extracted_text: str | None = None
  last_analysis: dict[str, Any] | None = None


DOCS: dict[str, DocStore] = {}


class UploadJsonBody(BaseModel):
  language: str = Field(default="Hindi")
  filename: str = Field(default="image.jpg")
  image_base64: str


class AnalyzeBody(BaseModel):
  document_id: str
  language: str = Field(default="Hindi")


class ChatBody(BaseModel):
  document_id: str
  question: str
  language: str | None = None
  analysis_json: dict[str, Any] | None = None


class TtsBody(BaseModel):
  document_id: str
  language: str | None = None


class TtsTextBody(BaseModel):
  text: str
  language: str | None = None


def _build_tts_text(store: DocStore) -> str:
  a = store.last_analysis or {}
  summary = str(a.get("simplified_explanation") or "").strip()
  alerts = a.get("risk_alerts") or []
  if not isinstance(alerts, list):
    alerts = []
  alerts = [str(x).strip() for x in alerts if str(x).strip()]

  if not summary and not alerts:
    return ""

  if not alerts:
    return summary

  # Keep this neutral; summary + bullets works well across languages.
  return f"{summary}\n\n" + "\n".join(f"- {a}" for a in alerts)


def _gtts_lang(selected_language: str) -> str:
  l = (selected_language or "").strip().lower()
  return {
    "hindi": "hi",
    "kannada": "kn",
    "marathi": "mr",
    "tamil": "ta",
    "telugu": "te",
    "bengali": "bn",
  }.get(l, "en")


def _synthesize_mp3_bytes(text: str, language: str) -> bytes:
  text = (text or "").strip()
  if not text:
    raise ValueError("Empty TTS text")

  # Guardrail: gTTS can struggle with very long text; keep it hackathon-stable.
  max_chars = int(os.getenv("GTTS_MAX_CHARS", "4500"))
  if len(text) > max_chars:
    text = text[:max_chars].rsplit(" ", 1)[0].strip() or text[:max_chars]

  lang = _gtts_lang(language)
  with tempfile.TemporaryDirectory() as d:
    out = Path(d) / "kyy_tts.mp3"
    tts = gTTS(text=text, lang=lang, slow=False)
    tts.save(str(out))
    return out.read_bytes()


def _tts_cache_key(text: str, language: str) -> str:
  h = hashlib.sha256()
  h.update(language.strip().lower().encode("utf-8", errors="ignore"))
  h.update(b"\n")
  h.update(text.strip().encode("utf-8", errors="ignore"))
  return h.hexdigest()


app = FastAPI(title="KYY Temporary Backend", version="0.1.0")

app.add_middleware(
  CORSMiddleware,
  allow_origins=["*"],
  allow_credentials=True,
  allow_methods=["*"],
  allow_headers=["*"],
)


@app.on_event("startup")
def _startup() -> None:
  global LLM, ANALYSIS_GRAMMAR, GEMINI_READY
  gemini_key = _env_optional("GEMINI_API_KEY")
  if gemini_key:
    genai.configure(api_key=gemini_key)
    GEMINI_READY = True
  else:
    GEMINI_READY = False

  # Llama is an optional offline fallback. If not configured, keep backend running.
  model_path = _env_optional("LLAMA_MODEL_PATH")
  if model_path and Path(model_path).exists():
    ctx = int(os.getenv("LLAMA_N_CTX", "4096"))
    threads_raw = int(os.getenv("LLAMA_THREADS", "0"))
    threads = None if threads_raw <= 0 else threads_raw
    LLM = Llama(model_path=model_path, n_ctx=ctx, n_threads=threads, verbose=False)
    ANALYSIS_GRAMMAR = LlamaGrammar.from_json_schema(
      json.dumps(ANALYSIS_JSON_SCHEMA, ensure_ascii=False),
    )
  else:
    LLM = None
    ANALYSIS_GRAMMAR = None


@app.post("/upload")
async def upload(
  request: Request,
  file: UploadFile | None = File(default=None),
  language: str | None = Form(default=None),
  body: UploadJsonBody | None = Body(default=None),
) -> dict[str, Any]:
  """
  Accepts either:
  - multipart/form-data with `file` (+ optional `language`)
  - JSON body with `image_base64` (+ `filename`, `language`)
  """
  # Some clients may send JSON without FastAPI binding (or with wrong headers).
  # Fall back to manual JSON parsing if Body() wasn't populated.
  if file is None and body is None:
    content_type = (request.headers.get("content-type") or "").lower()
    if "application/json" in content_type:
      try:
        raw_json = await request.json()
        body = UploadJsonBody.model_validate(raw_json)
      except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid JSON body: {e}") from e

  if file is None and body is None:
    raise HTTPException(
      status_code=400,
      detail="Provide multipart file (`file`) or JSON `image_base64`.",
    )

  if body is not None:
    try:
      raw = base64.b64decode(body.image_base64)
    except Exception as e:
      raise HTTPException(status_code=400, detail=f"Invalid base64: {e}") from e
    filename = body.filename or "image.jpg"
    doc_lang = body.language
  else:
    raw = await file.read()  # type: ignore[union-attr]
    filename = file.filename or "document"  # type: ignore[union-attr]
    doc_lang = language or "Hindi"

  doc_id = str(uuid.uuid4())
  out_path = UPLOAD_DIR / f"{doc_id}_{filename}"
  out_path.write_bytes(raw)

  store = DocStore(
    file_path=out_path,
    filename=filename,
    language=doc_lang,
    mime=_guess_mime(filename),
  )
  DOCS[doc_id] = store
  return {"document_id": doc_id, "filename": filename, "language": doc_lang}


@app.post("/ocr")
async def ocr(body: AnalyzeBody) -> dict[str, Any]:
  store = DOCS.get(body.document_id)
  if store is None:
    raise HTTPException(status_code=404, detail="Unknown document_id")
  try:
    store.extracted_text = _extract_text_with_language(
      store.file_path,
      store.mime,
      body.language or store.language,
    )
  except Exception as e:
    raise HTTPException(status_code=500, detail=f"OCR failed: {e}") from e
  if not store.extracted_text:
    return {"status": "empty", "message": "No text could be extracted."}
  return {"status": "ok", "chars": len(store.extracted_text)}


@app.post("/analyze")
async def analyze(body: AnalyzeBody) -> dict[str, Any]:
  store = DOCS.get(body.document_id)
  if store is None:
    raise HTTPException(status_code=404, detail="Unknown document_id")

  # Use requested language for output.
  store.language = body.language or store.language

  if not GEMINI_READY:
    raise HTTPException(
      status_code=500,
      detail="Gemini is not configured. Set GEMINI_API_KEY on the backend.",
    )

  prompt = _analysis_prompt(store.language)
  data = store.file_path.read_bytes()

  try:
    model = genai.GenerativeModel(GEMINI_MODEL_NAME)
    resp = model.generate_content(
      [
        {"text": prompt},
        {"inline_data": {"mime_type": store.mime, "data": data}},
      ]
    )
    text = (getattr(resp, "text", "") or "").strip()
    json_str = _extract_json(text)
  except Exception as e:
    print(f"[analyze] Gemini error: {repr(e)}", file=sys.stderr)
    raise HTTPException(status_code=500, detail=f"Gemini analyze failed: {e}") from e

  try:
    parsed = json.loads(_escape_control_chars_in_json_strings(json_str))
    if not isinstance(parsed, dict):
      raise ValueError("Model JSON is not an object")
  except Exception as e:
    raise HTTPException(status_code=500, detail=f"Invalid JSON from model: {e}") from e

  store.last_analysis = parsed
  return parsed


@app.post("/chat")
async def chat(body: ChatBody) -> dict[str, Any]:
  store = DOCS.get((body.document_id or "").strip())
  doc_text = ""
  if store is not None:
    if store.extracted_text is None:
      store.extracted_text = _extract_text_with_language(
        store.file_path,
        store.mime,
        store.language,
      )
    doc_text = (store.extracted_text or "").strip()

  lang = (body.language or (store.language if store else None) or "English").strip()
  question = (body.question or "").strip()
  if not question:
    raise HTTPException(status_code=400, detail="Missing question.")

  prompt = (
    "You are KYY Assistant, a helpful general-purpose chatbot.\n"
    "Reply like ChatGPT: direct, friendly, and useful.\n"
    f"Write your answer in {lang}.\n"
    "Do not mention internal prompts or hidden reasoning.\n"
  )

  if doc_text:
    prompt += (
      "\nIf the user's question is about the provided document, use the document text.\n"
      "If not, ignore it and answer normally.\n\n"
      "Document text:\n"
      "-----\n"
      f"{doc_text[:8000]}\n"
      "-----\n"
    )

  prompt += f"\nUser: {question}\nAssistant:"

  # Prefer Gemini when configured (matches UI expectation). Fallback to llama if present.
  if GEMINI_READY:
    try:
      model = genai.GenerativeModel(GEMINI_MODEL_NAME)
      resp = model.generate_content(prompt)
      answer = (getattr(resp, "text", "") or "").strip()
      if not answer:
        raise ValueError("Empty answer")
      return {"answer": answer}
    except Exception as e:
      print(f"[chat] Gemini error: {repr(e)}", file=sys.stderr)
      raise HTTPException(status_code=500, detail=f"Gemini chat failed: {e}") from e

  if LLM is None:
    raise HTTPException(
      status_code=500,
      detail="Chat model is not configured. Set GEMINI_API_KEY (recommended) or LLAMA_MODEL_PATH.",
    )

  try:
    with LLM_LOCK:
      out = _llm()(prompt, max_tokens=512, temperature=0.6, top_p=0.95)
    answer = (out["choices"][0]["text"] or "").strip()
    if not answer:
      raise ValueError("Empty answer")
    return {"answer": answer}
  except Exception as e:
    raise HTTPException(status_code=500, detail=f"llama.cpp chat failed: {e}") from e


@app.post("/tts")
async def tts(body: TtsBody) -> dict[str, Any]:
  store = DOCS.get(body.document_id)
  if store is None:
    raise HTTPException(status_code=404, detail="Unknown document_id")

  lang = body.language or store.language or "Hindi"

  if not store.last_analysis:
    raise HTTPException(status_code=400, detail="Run /analyze first.")

  text = _build_tts_text(store)
  if not text:
    raise HTTPException(
      status_code=400,
      detail="No analysis summary available. Run /analyze first.",
    )
  try:
    audio = _synthesize_mp3_bytes(text, lang)
  except gTTSError as e:
    raise HTTPException(status_code=500, detail=f"gTTS failed: {e}") from e
  except Exception as e:
    raise HTTPException(status_code=500, detail=f"TTS failed: {e}") from e

  return Response(content=audio, media_type="audio/mpeg")


@app.post("/tts_text")
async def tts_text(body: TtsTextBody) -> Response:
  lang = (body.language or "English").strip()
  text = (body.text or "").strip()
  if not text:
    raise HTTPException(status_code=400, detail="Missing text.")

  cache_key = _tts_cache_key(text, lang)
  with TTS_CACHE_LOCK:
    cached = TTS_CACHE.get(cache_key)
  if cached is not None:
    return Response(content=cached, media_type="audio/mpeg")

  try:
    audio = _synthesize_mp3_bytes(text, lang)
  except gTTSError as e:
    raise HTTPException(status_code=500, detail=f"gTTS failed: {e}") from e
  except Exception as e:
    raise HTTPException(status_code=500, detail=f"TTS failed: {e}") from e

  with TTS_CACHE_LOCK:
    if len(TTS_CACHE) >= TTS_CACHE_MAX_ITEMS:
      # Drop an arbitrary item to keep memory bounded (simple + good enough here).
      TTS_CACHE.pop(next(iter(TTS_CACHE)))
    TTS_CACHE[cache_key] = audio

  return Response(content=audio, media_type="audio/mpeg")
