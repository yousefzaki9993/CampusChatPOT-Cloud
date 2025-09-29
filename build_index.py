import os, json, pickle
from sentence_transformers import SentenceTransformer

# Paths
BASE_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.join(BASE_DIR, "data")
FAQS_PATH = os.path.join(DATA_DIR, "faqs.json")
VECTORS_PATH = os.path.join(DATA_DIR, "bert_embeddings.pkl")

def build():
    # Load FAQs
    with open(FAQS_PATH, "r", encoding="utf-8") as f:
        faqs = json.load(f)

    questions = [faq["question"] for faq in faqs]

    # Load Sentence-BERT model
    print("🔄 Loading BERT model (all-MiniLM-L6-v2)...")
    model = SentenceTransformer("all-MiniLM-L6-v2")

    # Encode all questions → embeddings
    print("🔄 Encoding questions...")
    embeddings = model.encode(questions, convert_to_numpy=True, normalize_embeddings=True)

    # Save embeddings
    with open(VECTORS_PATH, "wb") as f:
        pickle.dump({"model": model, "embeddings": embeddings}, f)

    abs_path = os.path.abspath(VECTORS_PATH)
    print(f"✅ BERT embeddings built and saved to: {abs_path}")

if __name__ == "__main__":
    build()
