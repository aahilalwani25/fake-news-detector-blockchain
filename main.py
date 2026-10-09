import os
import re
import hashlib
import json
from multichain import MultiChainClient
from nlp_feature_extractor import NLPFeatureExtractor

# ----------------------------------------------------------------------
# 1. Load Local Chain Credentials
# ----------------------------------------------------------------------
def get_credentials(chain_name="fakedetectchain"):
    appdata = os.environ.get("APPDATA")
    if appdata:
        conf = os.path.join(appdata, "MultiChain", chain_name, "multichain.conf")
    else:
        conf = os.path.expanduser(f"~/.multichain/{chain_name}/multichain.conf")
        
    user, pwd, port = "multichainrpc", "", 7216
    print(f"Loading credentials from: {conf}")
    with open(conf, "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith("rpcuser="): user = line.split("=", 1)[1]
            elif line.startswith("rpcpassword="): pwd = line.split("=", 1)[1]
            elif line.startswith("rpcport="): port = int(line.split("=", 1)[1])
    return user, pwd, port


# ----------------------------------------------------------------------
# 3. Main Execution
# ----------------------------------------------------------------------
if __name__ == "__main__":
    CHAIN = "fakedetectchain"
    user, pwd, port = get_credentials(CHAIN)
    print(f"Using credentials - User: {user}, Port: {port}")
    
    # Initialize MultiChainClient using official interface
    mc = MultiChainClient(host="127.0.0.1", port=port, username=user, password=pwd, usessl=False)
    mc.setoption("chainname", CHAIN)

    # 1. Fetch identities
    addrs = mc.getaddresses()
    if not mc.success():
        print(f"Connection failed: {mc.errorcode()} - {mc.errormessage()}")
        exit(1)

    admin_addr = addrs[0]
    pub_addr = addrs[1] if len(addrs) > 1 else mc.getnewaddress()
    val_addr = addrs[2] if len(addrs) > 2 else mc.getnewaddress()

    print(f"Connected to {CHAIN} on port {port}")
    print(f"Admin:     {admin_addr}")
    print(f"Publisher: {pub_addr}")
    print(f"Validator: {val_addr}")

    # 2. Sample News
    article = {
        "id": "NEWS-TEST-001",
        "title": "Researchers publish clinical data confirming trial results",
        "body": "Official health teams and researchers published evidence with empirical data.",
        "url": "https://www.reuters.com/health"
    }

    content_hash = hashlib.sha256(f"{article['title']}\n{article['body']}".encode()).hexdigest()

    # 3. Publisher posts to news_registry using native JSON format
    tx_pub = mc.publishfrom(
        pub_addr,
        "news_registry",
        article["id"],
        {"json": {"title": article["title"], "url": article["url"], "hash": content_hash}}
    )
    if mc.success():
        print(f"\n[news_registry] Article published. TxID: {tx_pub}")
    else:
        print(f"Publish failed: {mc.errormessage()}")

    # 4. Feature Extraction & Decision
    nlp = NLPFeatureExtractor()
    features = nlp.extract(article["title"], article["body"], article["url"])
    print(f"NLP Metrics: {json.dumps(features)}")

    # Decision rule
    verdict = "Real" if (features["real_score"] > features["fake_score"] and features["domain_real"] > 0) else "Fake"
    reward = 10 if verdict == "Real" else 0
    print(f"Verdict: {verdict} | Credibility Reward: {reward}")

    # 5. Validator certifies into validation_stream
    tx_val = mc.publishfrom(
        val_addr,
        "validation_stream",
        article["id"],
        {"json": {"verdict": verdict, "metrics": features, "status": "CERTIFIED"}}
    )
    if mc.success():
        print(f"[validation_stream] Validation recorded. TxID: {tx_val}")

    # 6. Reward Publisher
    if reward > 0:
        tx_rew = mc.sendasset(pub_addr, "CredibilityToken", reward)
        if mc.success():
            print(f"Awarded {reward} CredibilityTokens. TxID: {tx_rew}")

    # 7. Check Balance
    balances = mc.getaddressbalances(pub_addr)
    print(f"Publisher Updated Balances: {json.dumps(balances, indent=2)}")