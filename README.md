# Fake Detector Blockchain

A prototype for validating news credibility using a blockchain ledger plus lightweight NLP scoring. The project connects to a local MultiChain node, publishes article metadata to a stream, evaluates the content with keyword/domain heuristics, and records a verdict for review and reward tracking.

## Project goal

This project is designed to demonstrate a simple trust model for online content:

- a publisher submits an article to a blockchain-backed registry
- the content is scored using a small NLP feature extractor
- a verdict is generated based on signal strength
- the result is written to a validation stream
- a credibility token can be awarded when the article is considered legitimate

## What is included

- [main.py](main.py) — the main demo that connects to MultiChain, publishes a sample article, analyzes the text, and stores the validation result
- [nlp_feature_extractor.py](nlp_feature_extractor.py) — reusable NLP scoring logic for fake/real signal extraction
- [multichain.py](multichain.py) — Python JSON-RPC client wrapper for MultiChain
- [NewTest.py](NewTest.py) — basic stream publishing and connection test script
- [fake-detector.bat](fake-detector.bat) — Windows batch script that initializes a local MultiChain chain and configures permissions

## How the workflow works

1. The script reads MultiChain RPC credentials from the local chain configuration file.
2. It connects to the chain and fetches blockchain addresses.
3. A sample article is published to the `news_registry` stream.
4. NLP signals are calculated from the title, body, and URL.
5. A verdict is computed using a simple rule-based decision:
   - real-word frequency
   - fake-word frequency
   - trusted/flagged domain checks
   - TF-IDF similarity against a small reference corpus
6. The verdict is published to the `validation_stream` stream.
7. If the article passes the credibility check, a reward asset can be transferred.

## Main NLP logic

The feature extractor uses a small vocabulary and domain list:

- `real_words`: words such as `researchers`, `study`, `confirmed`, `official`, `published`, `evidence`
- `fake_words`: words such as `conspiracy`, `miracle`, `hoax`, `secret`, `exposed`
- `trusted_domains`: `reuters.com`, `bbc.com`, `apnews.com`
- `flagged_domains`: `dailyhoax.xyz`, `secretleak.net`

It also computes TF-IDF similarity against a simple trusted corpus to estimate whether the content matches a credible article style.

## Requirements

Before running the project, make sure you have:

- Python 3.9+
- `scikit-learn`
- a working MultiChain installation with `multichain-util`, `multichain-cli`, and `multichaind`
- a configured chain with RPC settings available in `multichain.conf`

Install the Python dependency with:

```bash
pip install scikit-learn
```

## MultiChain setup

The project expects a chain named `fakedetectchain` and reads RPC settings from the standard MultiChain config path:

```text
%APPDATA%\MultiChain\fakedetectchain\multichain.conf
```

The script reads the following values automatically:

- `rpcuser`
- `rpcpassword`
- `rpcport`

To initialize the local chain on Windows, run:

```bat
fake-detector.bat
```

This batch file creates the chain, starts the daemon, creates streams, and configures role permissions and asset issuance.

## Running the demo

From the project directory, run:

```bash
python main.py
```

The script will:

1. connect to the chain
2. load the chain credentials
3. fetch blockchain addresses
4. publish a sample article
5. calculate NLP metrics
6. generate a verdict
7. send the validation result to the blockchain stream
8. optionally award a credibility token

## Example output

Typical output includes:

- the chain name and RPC port
- admin, publisher, and validator addresses
- published transaction IDs
- NLP metric values like `fake_score`, `real_score`, and `sim_matched`
- a verdict such as `Real` or `Fake`
- reward and balance data if the article passes validation

## Notes

- This is a prototype, not a production-grade misinformation detector.
- The NLP scoring is intentionally rule-based and lightweight.
- The vocabulary, domains, and corpus are hardcoded for demonstration purposes.
- Chain permissions and asset rules should be reviewed before any real-world deployment.

## License

This project is intended for learning, experimentation, and local prototype use. Review the source files and any included library licensing before using or redistributing it beyond a personal or educational environment.
