# Fake Detector Blockchain

A blockchain-based fake news validation prototype that combines MultiChain smart publishing with a simple NLP credibility check. The project stores article metadata in a MultiChain stream, analyzes article wording and domain signals, and records a validation verdict on-chain.

## Overview

This project demonstrates a lightweight workflow for verifying online content:

- A publisher submits a news article to the `news_registry` stream.
- The system extracts NLP features from the title, body, and URL.
- A verdict is computed based on keyword frequency, domain reputation, and similarity to a trusted reference corpus.
- The validator records the outcome in the `validation_stream` stream.
- A reputation token can be awarded when an article is classified as legitimate.

The implementation uses:

- Python
- scikit-learn for TF-IDF feature scoring
- MultiChain JSON-RPC for blockchain interaction
- Stream-based data storage and role-based permissions

## Project Files

- [nlp_fake_detector_chain.py](nlp_fake_detector_chain.py) — main application logic for loading chain credentials, extracting NLP features, publishing article data, validating the article, and rewarding credibility.
- [multichain.py](multichain.py) — Python client wrapper for MultiChain JSON-RPC
- [NewTest.py](NewTest.py) — test/demo script for basic MultiChain stream creation and publishing
- [fake-detector.bat](fake-detector.bat) — Windows batch script that sets up a local MultiChain chain and configures stream permissions

## Features

- MultiChain connection and credential loading from `multichain.conf`
- NLP-based fake/real classification signals
- Trusted and flagged domain checks
- TF-IDF similarity scoring against a small trusted corpus
- Blockchain publication of article records and validation outcomes
- Credibility token issuance and balance lookup

## Prerequisites

Before running the project, ensure the following are installed:

- Python 3.9+
- `scikit-learn`
- A working MultiChain node installation with `multichain-util`, `multichain-cli`, and `multichaind` available on your PATH
- Access to a configured MultiChain chain named `fakedetectchain`

You can install the Python dependency with:

```bash
pip install scikit-learn
```

## Local MultiChain Setup

The project expects a MultiChain chain and RPC credentials in the standard MultiChain configuration folders.

Typical configuration path:

```text
%APPDATA%\MultiChain\fakedetectchain\multichain.conf
```

The app reads:

- `rpcuser`
- `rpcpassword`
- `rpcport`

from this file automatically.

A local chain can be bootstrapped using the included Windows launcher:

```bat
fake-detector.bat
```

This script creates the chain, sets basic permissions, starts the daemon, creates streams, and sets up asset and role permissions.

## Running the Project

From the project folder, run:

```bash
python main.py
```

This will:

1. Connect to the MultiChain node
2. Read the configured chain credentials
3. Fetch addresses from the chain
4. Publish a sample article to `news_registry`
5. Evaluate article credibility using NLP metrics
6. Record the verdict in `validation_stream`
7. Award a credibility token if the article is considered real

## Example Behavior

The sample article in the script is a Reuters-style article that should score as real because it contains trusted-source terminology and a higher `real_score` than `fake_score`.

Example output includes:

- connected chain name and ports
- publisher, validator, and admin addresses
- published transaction IDs
- NLP metric scores
- final verdict such as `Real` or `Fake`
- balance and reward information

## Notes

- This is a prototype and uses a small hardcoded vocabulary and corpus.
- It is designed for demonstration and local testing rather than production-grade fake news detection.
- The blockchain and stream permissions should be reviewed and hardened before real deployment.

## License

This project is provided for educational and prototype use. Please check the included source headers and MultiChain library licensing before redistribution or commercial deployment.
