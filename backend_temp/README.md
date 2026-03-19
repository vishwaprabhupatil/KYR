# KYY Temporary Backend (FastAPI + Gemini)

Minimal FastAPI backend you can run locally while your main backend finishes installing.

## Setup

```bash
cd backend_temp
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
brew install tesseract
export LLAMA_MODEL_PATH="models/phi-3-mini-4k-instruct-q4_k_m.gguf"
export GEMINI_API_KEY="YOUR_GEMINI_KEY"
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

From your phone (same Wi‑Fi), verify:

`http://<YOUR_LAPTOP_LAN_IP>:8000/docs`

## Notes

- Stores uploads in `backend_temp/uploads/` and keeps state in memory (hackathon-friendly).
- Endpoints implemented: `POST /upload`, `POST /ocr`, `POST /analyze`, `POST /chat`, `POST /tts`.
- Uses Gemini for `/analyze` (summary + risks) and llama.cpp via `llama-cpp-python` for `/chat`.
- Uses `gTTS` for `/tts` (requires internet access from the backend machine).
- Configure Flutter base URL in `lib/core/constants.dart` to your LAN IP.
