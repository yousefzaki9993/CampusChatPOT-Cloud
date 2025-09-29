from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import json
import os
import numpy as np
import pickle
from sklearn.metrics.pairwise import cosine_similarity
from sentence_transformers import SentenceTransformer

BASE_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.join(BASE_DIR, "data")
FAQS_PATH = os.path.join(DATA_DIR, "faqs.json")
VECTORS_PATH = os.path.join(DATA_DIR, "bert_embeddings.pkl")

app = Flask(__name__, static_folder="frontend", static_url_path="/")
CORS(app)

# Load FAQs
def load_faqs():
    with open(FAQS_PATH, "r", encoding="utf-8") as f:
        faqs = json.load(f)
    return faqs

# Load BERT model and embeddings
def load_embeddings():
    if os.path.exists(VECTORS_PATH):
        with open(VECTORS_PATH, "rb") as f:
            obj = pickle.load(f)
        return obj["model"], obj["embeddings"]
    return None, None

FAQS = load_faqs()
MODEL, EMBEDDINGS = load_embeddings()

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

    global MODEL, EMBEDDINGS, FAQS
    if MODEL is None or EMBEDDINGS is None:
        return jsonify({
            "answer": "Knowledge base not ready. Please run build_index.py first.",
            "score": 0.0
        }), 500

    # Encode user message
    user_emb = MODEL.encode([user_msg], convert_to_numpy=True, normalize_embeddings=True)
    sims = cosine_similarity(user_emb, EMBEDDINGS).flatten()

    best_idx = int(np.argmax(sims))
    best_score = float(sims[best_idx])

    THRESHOLD = 0.55  # threshold for confidence

    if best_score < THRESHOLD:
        # get top 3 suggestions
        top_idx = sims.argsort()[-3:][::-1]
        suggestions = [FAQS[i]["question"] for i in top_idx]

        return jsonify({
            "answer": "Let me make sure I understood your question correctly.",
            "clarification": "Did you mean one of these?",
            "suggestions": suggestions,
            "score": best_score
        })

    answer = FAQS[best_idx]["answer"]
    return jsonify({
        "answer": answer,
        "score": best_score,
        "source_id": best_idx,
        "source_question": FAQS[best_idx]["question"]
    })

if __name__ == "__main__":
    import os
    port = int(os.environ.get("PORT", 5000))
    debug = os.environ.get("FLASK_ENV") != "production"
    app.run(host="0.0.0.0", port=port, debug=debug)
