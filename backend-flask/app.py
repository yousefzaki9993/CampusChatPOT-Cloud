# app.py
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import json
import os
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import pickle

BASE_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.join(BASE_DIR, "data")
VECTORS_PATH = os.path.join(DATA_DIR, "tfidf.pkl")
FAQS_PATH = os.path.join(DATA_DIR, "faqs.json")

app = Flask(__name__, static_folder="frontend", static_url_path="/")
CORS(app)

# Load FAQs and vectorizer
def load_faqs():
    with open(FAQS_PATH, "r", encoding="utf-8") as f:
        faqs = json.load(f)
    return faqs

def load_vectorizer():
    if os.path.exists(VECTORS_PATH):
        with open(VECTORS_PATH, "rb") as f:
            obj = pickle.load(f)
        return obj["vectorizer"], obj["tfidf_matrix"]
    return None, None

FAQS = load_faqs()
VECT, TFIDF_MATRIX = load_vectorizer()

@app.route("/")
def index():
    return send_from_directory(app.static_folder, "index.html")

@app.route("/api/faq-list", methods=["GET"])
def faq_list():
    return jsonify([{"id": i, "q": faq["question"]} for i, faq in enumerate(FAQS)])

@app.route("/api/chat", methods=["POST"])
def chat():
    data = request.get_json(force=True)
    user_msg = (data.get("msg") or "").strip()
    if not user_msg:
        return jsonify({"error": "Empty message"}), 400

    global VECT, TFIDF_MATRIX, FAQS
    if VECT is None or TFIDF_MATRIX is None:
        return jsonify({
            "answer": "Knowledge base not ready. Please run build_index.py first.",
            "score": 0.0
        }), 500

    user_vec = VECT.transform([user_msg])
    sims = cosine_similarity(user_vec, TFIDF_MATRIX).flatten()
    best_idx = int(np.argmax(sims))
    best_score = float(sims[best_idx])

    THRESHOLD = 0.45

    if best_score < THRESHOLD:
        return jsonify({
            "answer": "Sorry, I couldn't understand your question. Please rephrase or contact academic support.",
            "score": best_score,
            "source_id": None,
            "source_question": None
        })

    answer = FAQS[best_idx]["answer"]
    return jsonify({
        "answer": answer,
        "score": best_score,
        "source_id": best_idx,
        "source_question": FAQS[best_idx]["question"]
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
