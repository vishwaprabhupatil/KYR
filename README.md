# ⚖️ KYY- Know Your Rights

> **AI-powered legal document understanding for everyone.**
> Turning complex legal contracts into clear, multilingual insights.

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)

![FastAPI](https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white)

![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?logo=supabase&logoColor=black)

![Google Gemini](https://img.shields.io/badge/Google%20Gemini-4285F4?logo=google&logoColor=white)


---

## 🚀 Overview

**KYY** is an AI-powered platform designed to make legal documents understandable for everyone — especially people who are unfamiliar with legal language.

Users can upload legal documents such as **contracts, agreements, or notices**, and the system will automatically:

* Extract the text
* Generate a **plain-language summary**
* Detect **risky clauses**
* Assign a **contract safety score**
* Provide explanations in **regional languages**

The platform also includes an **AI legal assistant (“Vaani AI”)** that allows users to ask questions about the document and receive contextual answers.

This makes legal knowledge **accessible, inclusive, and practical**, particularly for rural and non-technical users. 

---

# ✨ Key Features

### 📄 AI Document Understanding

Upload **PDFs or photos** of legal documents and instantly receive structured analysis.

### 🧠 Plain Language Summaries

Complex legal terms are translated into **simple, easy-to-understand explanations**.

### ⚠️ Risky Clause Detection

The system automatically identifies **potentially dangerous clauses** and provides warnings.

### 🛡️ Contract Safety Score

Each document receives a **risk level and safety score** to help users evaluate agreements quickly.

### 🌍 Multilingual Support

Supports major Indian languages including:

* Hindi
* Kannada
* Marathi
* Tamil
* Telugu
* Bengali

### 🤖 Vaani AI Chatbot

Users can ask questions like:

> “Is this contract safe to sign?”
> “What happens if I terminate this agreement?”
> “Explain clause 4 in simple terms.”

### 🔊 Audio Playback

Summaries can be converted into **speech**, making the system accessible to users with low literacy.

### 👤 User Accounts & History

Users can log in to:

* Save analyzed documents
* Access past summaries
* Continue previous AI chats

---

# 🏗 System Architecture

```
User (Flutter Mobile App)
        │
        ▼
FastAPI Backend (Python)
        │
 ┌───────────────┬───────────────┬───────────────┐
 ▼               ▼               ▼
OCR Engine     Gemini API     llama.cpp
(Tesseract)   (Summarization) (AI Chatbot)
        │
        ▼
Supabase (Auth + PostgreSQL)
        │
        ▼
TTS Engine (gTTS → MP3)
```

---

# 🧰 Tech Stack

## Mobile App

* **Flutter (Material 3)**
* **Dart**
* **Provider** – State Management
* **Dio** – REST API networking
* **file_picker** – Document uploads
* **audioplayers** – Voice playback

## Backend

* **FastAPI (Python)**
* **Supabase** – Authentication & PostgreSQL database

## AI / ML

* **Google Gemini API** – Document summarization & risk analysis
* **llama.cpp (GGUF models)** – AI chatbot responses

## Document Processing

* **Tesseract OCR** (`pytesseract`) – Image text extraction
* **pypdf** – PDF parsing

## Text-to-Speech

* **gTTS** – Generates MP3 audio summaries

---

# 📱 Application Flow

1️⃣ User uploads a **PDF or document image**
2️⃣ OCR extracts text from the document
3️⃣ Gemini analyzes and generates:

* Summary
* Risk analysis
* Safety score
  4️⃣ Results are stored in **Supabase**
  5️⃣ User can:
* Listen to the summary
* Ask questions via **Vaani AI**
* Revisit previous documents

---

# 📈 Scalability

The platform is designed to scale across regions and communities.

* Works even with **slow or unstable internet connections**
* Can expand from **district → state → national level**
* Easily supports **additional languages**
* Stores user history for long-term document tracking
* Suitable for deployment through **legal aid centers, NGOs, and government initiatives**

---

# 🎯 Vision

Legal knowledge should not be limited to lawyers or experts.

**Vaani Kanoon** aims to democratize legal understanding by combining:

* Artificial Intelligence
* Multilingual accessibility
* Voice-based interaction
* Mobile-first design

The goal is to ensure that **every citizen can understand the agreements they sign and the rights they hold.**

---


