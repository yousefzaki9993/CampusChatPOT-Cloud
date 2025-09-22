# build_index.py
import os, json, pickle
from sklearn.feature_extraction.text import TfidfVectorizer

BASE_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.join(BASE_DIR, "data")
FAQS_PATH = os.path.join(DATA_DIR, "faqs.json")
VECTORS_PATH = os.path.join(DATA_DIR, "tfidf.pkl")

def build():
    with open(FAQS_PATH, "r", encoding="utf-8") as f:
        faqs = json.load(f)

    corpus = [faq["question"] + " " + faq.get("answer","") for faq in faqs]
    vectorizer = TfidfVectorizer(ngram_range=(1,2), max_df=0.85)
    tfidf_matrix = vectorizer.fit_transform(corpus)

    with open(VECTORS_PATH, "wb") as f:
        pickle.dump({"vectorizer": vectorizer, "tfidf_matrix": tfidf_matrix}, f)

    print("Index built. Saved to:", VECTORS_PATH)

if __name__ == "__main__":
    build()
