import re
from sklearn.feature_extraction.text import TfidfVectorizer

# ----------------------------------------------------------------------
# 2. NLP Feature Extraction
# ----------------------------------------------------------------------
class NLPFeatureExtractor:
    def __init__(self):
        self.fake_words = {"unbelievable", "shocking", "conspiracy", "miracle", "hoax", "exposed", "secret"}
        self.real_words = {"researchers", "study", "confirmed", "peer-reviewed", "official", "published", "evidence"}
        self.trusted_domains = {"reuters.com", "bbc.com", "apnews.com"}
        self.flagged_domains = {"dailyhoax.xyz", "secretleak.net"}
        self.corpus = [
            "Clinical trial publishes conclusive evidence verified by scientific researchers.",
            "Official statement issued by public health authorities with empirical data."
        ]
        self.vec = TfidfVectorizer(stop_words="english")
        self.vec.fit(self.corpus)

    def extract(self, title, body, url):
        clean = " ".join(re.sub(r"[^a-zA-Z\s]", " ", f"{title} {body}".lower()).split())
        words = clean.split()
        n = max(len(words), 1)

        fake_score = round(sum(1 for w in words if w in self.fake_words) / n * 100.0, 3)
        real_score = round(sum(1 for w in words if w in self.real_words) / n * 100.0, 3)
        domain_real = 1.0 if any(d in url.lower() for d in self.trusted_domains) else 0.0
        domain_fake = 1.0 if any(d in url.lower() for d in self.flagged_domains) else 0.0

        try:
            cv = self.vec.transform([clean])
            qv = self.vec.transform(self.corpus)
            sim_matched = round(float((cv * qv.T).toarray()[0].max()) * 100.0, 3)
        except Exception:
            sim_matched = 0.0

        return {
            "fake_score": fake_score, "real_score": real_score,
            "domain_real": domain_real, "domain_fake": domain_fake,
            "sim_matched": sim_matched
        }
