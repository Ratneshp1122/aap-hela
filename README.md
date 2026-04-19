<div align="center">

<img src="https://img.shields.io/badge/HeLa_Chain-L1_Blockchain-8A2BE2?style=for-the-badge&logo=ethereum" alt="HeLa Chain"/>
<img src="https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python"/>
<img src="https://img.shields.io/badge/FastAPI-0.111+-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI"/>
<img src="https://img.shields.io/badge/LangGraph-Multi_Agent-FF6B35?style=for-the-badge" alt="LangGraph"/>
<img src="https://img.shields.io/badge/IPFS-Pinata-6E46AE?style=for-the-badge" alt="IPFS"/>
<img src="https://img.shields.io/badge/ELK-Observability-005571?style=for-the-badge&logo=elastic" alt="ELK"/>

# 🔐 AAP — Agent Audit Protocol
### *The Trust Layer for Autonomous AI Agents*

**A blockchain-anchored, DAO-governed transparency and accountability framework for AI trading agents — built on HeLa L1.**

[📺 Demo](#-demo) · [🚀 Quick Start](#-quick-start) · [📐 Architecture](#-architecture) · [✨ Features](#-features) · [📖 API Docs](#-api-reference) · [🗺️ Roadmap](#️-roadmap)

</div>

---

## 📌 Table of Contents

- [Overview](#-overview)
- [Problem Statement](#-problem-statement)
- [Features](#-features)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Quick Start](#-quick-start)
- [Full Setup Guide](#-full-setup-guide)
- [Environment Variables](#-environment-variables)
- [Smart Contracts](#-smart-contracts)
- [API Reference](#-api-reference)
- [Dashboard Guide](#-dashboard-guide)
- [Multi-Agent System](#-multi-agent-system)
- [Verification System](#-verification-system)
- [DAO Governance](#-dao-governance)
- [ELK Observability](#-elk-observability)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌐 Overview

**AAP (Agent Audit Protocol)** is a full-stack, production-ready platform that solves the **"black box AI" problem** in high-stakes environments. It ensures every decision made by an autonomous AI trading agent is:

- 📋 **Logged** as a structured Protocol Decision Record (PDR)
- 🌐 **Stored** on IPFS for decentralized, censorship-resistant access
- ⬡ **Anchored** on HeLa blockchain for immutable proof of existence
- 🔍 **Verifiable** through 3 levels of cryptographic verification
- 🗳️ **Governable** via a 24-hour DAO challenge and voting mechanism
- 💬 **Accessible** through a consumer-grade AI chatbot interface

---

## 🚨 Problem Statement

- **Black Box Decisions** — AI agents make critical financial decisions with no explanation
- **No Accountability** — No standardized way to trace or audit agent actions
- **No Human Oversight** — Governing bodies cannot verify or challenge agent decisions
- **High-Stakes Risk** — In finance and automation, unchecked AI creates systemic risk

---

## ✨ Features

### 🤖 AI & Agent Layer
| Feature | Description |
|---|---|
| **Multi-Agent Orchestrator** | Routes queries to Llama 3, Gemini 1.5 Pro, GPT-4o, or Claude 3.5 Sonnet |
| **Reputation-Gated Access** | Premium agents unlock only when user reputation score crosses thresholds |
| **Chatbot-First Interface** | Consumer-grade AI chat with markdown rendering and animated bubbles |
| **Quick Actions** | One-click prompts for top NSE stocks, crypto, and portfolio analysis |
| **Signal Analysis** | RSI(14), MACD, Bollinger Bands, Volume, India VIX, News Sentiment |
| **Confidence Scoring** | Every decision includes a `0.0–1.0` confidence score with rationale |
| **Risk Classification** | Decisions tagged `LOW / MEDIUM / HIGH / CRITICAL` with numeric score |
| **Human-Readable Explanation** | Plain-English summary of every AI decision |

### 📊 Multi-Asset Coverage
| Asset Class | Data Source | Examples |
|---|---|---|
| **NSE Equities** | yfinance | RELIANCE, TCS, HDFC, INFY, WIPRO, ICICIBANK |
| **Cryptocurrency** | ccxt / CoinGecko | BTC, ETH with Fear/Greed index |
| **Mutual Funds** | MFAPI | Parag Parikh, Mirae Asset, HDFC Mid-Cap |

### 🔗 Blockchain & Storage
| Feature | Description |
|---|---|
| **PDR Schema** | Structured JSON with SHA-256 hash chain for tamper detection |
| **IPFS Upload** | Every PDR pinned to IPFS via Pinata with unique CID |
| **Merkle Batching** | 10 PDRs batched per Merkle tree — one cheap on-chain transaction |
| **HeLa Anchoring** | Merkle root written to `AuditAnchor.sol` on HeLa L1 |
| **Simulation Mode** | All blockchain/IPFS operations fully simulated when keys absent |

### 🔍 3-Level Verification
| Level | Method | What it proves |
|---|---|---|
| **Level 1** | SHA-256 Hash Re-computation | Data integrity — record was not tampered |
| **Level 2** | Deterministic Agent Replay | Decision correctness — same inputs produce same output |
| **Level 3** | ZK-SNARK (Groth16) | Mathematical proof of correctness without revealing strategy |

### 🗳️ DAO Governance
| Feature | Description |
|---|---|
| **Challenge Window** | 24-hour window to dispute any agent decision |
| **Token-Weighted Voting** | HELA token stake required to raise challenge |
| **Auto-Resolution** | Majority vote upholds or dismisses challenge |
| **Reputation Impact** | Successful challenges increase rep; failed ones lose stake |
| **On-Chain Registry** | All challenges recorded in `ChallengeRegistry.sol` |

### 📈 Forecasting Engine
| Feature | Description |
|---|---|
| **EMA Forecasting** | Exponential Moving Average with 5-day price projection |
| **Confidence Intervals** | 90% confidence bands (upper/lower bounds) |
| **Trend Classification** | `BULLISH / BEARISH / SIDEWAYS` with strength score |
| **Statistical Fallback** | `statsmodels` ARIMA if prophet is unavailable |

### 📡 Real-Time Dashboard
| Page | Features |
|---|---|
| **Overview / Chatbot** | AI chat, market ticker, agent selector, protocol flow, live stats |
| **Decisions** | Full PDR table, filter by status/symbol, verification badge |
| **Challenges** | Open disputes, vote panel, 24h countdown |
| **Portfolio** | Donut chart, P&L, sector allocation, agent decision timeline |
| **Governance** | DAO status, voting history, reputation leaderboard |

### 🔭 Observability (ELK)
| Component | Role |
|---|---|
| **Elasticsearch** | Stores all PDR, chat, and API log events |
| **Logstash** | Ingests and normalizes events with daily rolling indices |
| **Kibana** | Visual dashboards: agent performance, risk heatmaps, API latency |
| **ELKShipper** | Async Python queue with JSONL fallback when ES is offline |

---

## 📐 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AAP Protocol Stack                        │
├─────────────────────────────────────────────────────────────┤
│  Browser Dashboard (HTML/CSS/JS)                            │
│  ├── Chatbot UI   ├── Portfolio   ├── Decisions   ├── DAO   │
├─────────────────────────────────────────────────────────────┤
│  FastAPI Backend (Python)                                   │
│  ├── REST API     ├── WebSocket Feed   ├── ChatHandler      │
├──────────────────────────┬──────────────────────────────────┤
│  Multi-Agent Layer       │  Protocol Layer                  │
│  ├── Gemini 1.5 Pro      │  ├── PDR Builder                 │
│  ├── GPT-4o (Rep ≥40)    │  ├── SHA-256 Hasher             │
│  ├── Claude 3.5 (Rep ≥70)│  ├── Merkle Batcher             │
│  └── Llama 3 (Free)      │  ├── IPFS Uploader (Pinata)     │
├──────────────────────────┤  └── HeLa Anchor                │
│  Data Layer              ├─────────────────────────────────│
│  ├── yfinance (NSE)      │  Blockchain Layer                │
│  ├── ccxt (Crypto)       │  ├── AuditAnchor.sol            │
│  └── MFAPI (MF)          │  ├── ChallengeRegistry.sol      │
├──────────────────────────┤  ├── PolicyRegistry.sol         │
│  Observability (ELK)     │  └── AgentRegistry.sol          │
│  Elasticsearch → Kibana  └─────────────────────────────────┤
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **AI Framework** | LangGraph, LangChain |
| **LLM Providers** | Google Gemini, OpenAI, Anthropic, Groq (Llama 3) |
| **Backend** | FastAPI, Uvicorn, WebSockets, SQLite |
| **Blockchain** | HeLa Chain L1 (Chain ID: 8668 Mainnet / 666 Testnet) |
| **Smart Contracts** | Solidity 0.8.20, Hardhat, ethers.js |
| **Decentralized Storage** | IPFS via Pinata |
| **Market Data** | yfinance, ccxt, MFAPI, pandas-ta |
| **Forecasting** | statsmodels, EMA, Prophet (optional) |
| **Zero-Knowledge Proofs** | Circom, snarkjs, Groth16 |
| **Frontend** | HTML5, CSS3 (Vanilla), JavaScript (ES6+) |
| **Observability** | Elasticsearch 8.13, Logstash, Kibana, Docker |
| **DevOps** | Docker Compose, Git |

---

## 🚀 Quick Start

> **No API keys required.** Runs fully in demo/simulation mode.

### Prerequisites

- Python ≥ 3.11 → [Download](https://python.org/downloads)
- Git → [Download](https://git-scm.com)

### 1. Clone the Repository

```bash
git clone https://github.com/Ratneshp1122/aap-hela.git
cd aap-hela
```

### 2. Install Dependencies

```bash
pip install langgraph langchain langchain-google-genai google-generativeai \
            fastapi "uvicorn[standard]" python-dotenv pydantic httpx \
            websockets requests pandas numpy yfinance pandas-ta web3 ccxt
```

### 3. Set Up Environment

```bash
# Windows
copy .env.example .env

# macOS / Linux
cp .env.example .env
```

### 4. Start Everything

**Terminal 1 — Dashboard:**
```bash
python -m http.server 7890 --directory dashboard
```

**Terminal 2 — Backend:**
```bash
uvicorn backend.main:app --port 8000 --reload
```

### 5. Open in Browser

| Service | URL |
|---|---|
| **Dashboard** | http://localhost:7890 |
| **API Docs** | http://localhost:8000/api/docs |

---

## 📦 Full Setup Guide

### Step 1 — Clone & Enter Directory

```bash
git clone https://github.com/Ratneshp1122/aap-hela.git
cd aap-hela
```

### Step 2 — Create & Activate Virtual Environment

```bash
# Create
python -m venv venv

# Activate — Windows
.\venv\Scripts\Activate.ps1
# OR (if execution policy blocks scripts)
.\venv\Scripts\activate.bat

# Activate — macOS/Linux
source venv/bin/activate
```

### Step 3 — Install All Dependencies

```bash
pip install -r requirements.txt
```

> If `pandas-ta` fails on Windows: `pip install pandas-ta --no-deps`

### Step 4 — Configure Environment Variables

```bash
cp .env.example .env
```

Edit `.env` — minimum required for live AI:

```env
GOOGLE_API_KEY=your_gemini_api_key_here
```

See [Environment Variables](#-environment-variables) for full list.

### Step 5 — Start Services

**Terminal 1 — Dashboard Server:**
```bash
python -m http.server 7890 --directory dashboard
```

**Terminal 2 — FastAPI Backend:**
```bash
uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
```

**Terminal 3 — AI Agent (optional, for automated analysis):**
```bash
python run_demo.py
```

### Step 6 — Enable Live Mode (Optional)

In `dashboard/app.js` line 11, change:
```js
const DEMO_MODE = true;  // → change to false
```

This connects the dashboard to the live FastAPI backend.

### Step 7 — Deploy Smart Contracts (Optional)

```bash
# Install Node.js dependencies
npm install

# Compile contracts
npx hardhat compile

# Deploy to HeLa Testnet
npx hardhat run scripts/deploy.js --network helaTestnet
```

Copy printed addresses to `.env`:
```env
AUDIT_ANCHOR_ADDRESS=0x...
CHALLENGE_REGISTRY_ADDRESS=0x...
```

---

## 🔐 Environment Variables

| Variable | Required | Description |
|---|---|---|
| `GOOGLE_API_KEY` | ⭐ Recommended | Gemini 1.5 Pro (primary agent LLM) |
| `OPENAI_API_KEY` | Optional | GPT-4o (Rep ≥40 users) |
| `ANTHROPIC_API_KEY` | Optional | Claude 3.5 Sonnet (Rep ≥70 users) |
| `GROQ_API_KEY` | Optional | Llama 3 70B (free tier, all users) |
| `PINATA_JWT` | Optional | IPFS upload via Pinata |
| `PINATA_API_KEY` | Optional | Pinata API key |
| `PINATA_SECRET_KEY` | Optional | Pinata secret key |
| `HELA_TESTNET_RPC` | Optional | HeLa Testnet RPC endpoint |
| `PRIVATE_KEY` | Optional | Wallet private key for contract deployment |
| `AUDIT_ANCHOR_ADDRESS` | Optional | Deployed AuditAnchor.sol address |
| `CHALLENGE_REGISTRY_ADDRESS` | Optional | Deployed ChallengeRegistry.sol address |
| `ALPACA_API_KEY` | Optional | Alpaca paper trading API key |
| `ALPACA_SECRET_KEY` | Optional | Alpaca paper trading secret |
| `ELASTICSEARCH_URL` | Optional | ELK stack URL (default: localhost:9200) |
| `BACKEND_PORT` | Optional | FastAPI port (default: 8000) |
| `CHALLENGE_WINDOW_HOURS` | Optional | DAO challenge window (default: 24) |
| `RISK_THRESHOLD_AUTO` | Optional | Auto-approve risk limit (default: 0.5) |

> All variables are **optional**. Without them, the system runs in full simulation mode.

---

## 📜 Smart Contracts

| Contract | File | Purpose |
|---|---|---|
| `AuditAnchor` | `contracts/AuditAnchor.sol` | Stores Merkle roots of PDR batches |
| `ChallengeRegistry` | `contracts/ChallengeRegistry.sol` | Records disputes and voting outcomes |
| `AgentRegistry` | `contracts/AgentRegistry.sol` | Registers and tracks approved AI agents |
| `PolicyRegistry` | `contracts/PolicyRegistry.sol` | Stores on-chain governance rules |

### Contract: AuditAnchor

```solidity
// Anchors Merkle root of 10 PDRs per transaction
function anchorBatch(bytes32 merkleRoot, string calldata ipfsCid, uint256 count) external
function verifyDecision(bytes32 leaf, bytes32[] calldata proof) external view returns (bool)
```

### Contract: ChallengeRegistry

```solidity
// Raise a challenge against a PDR (requires HELA stake)
function raiseChallenge(string calldata decisionId, string calldata reason) external
// Vote on open challenge
function vote(uint256 challengeId, bool support) external
// Resolve after 24h window closes
function resolve(uint256 challengeId) external
```

### HeLa Network Config

| Network | Chain ID | RPC |
|---|---|---|
| Testnet | 666 | https://testnet-rpc.helachain.com |
| Mainnet | 8668 | https://mainnet-rpc.helachain.com |

Add to MetaMask or `hardhat.config.js`:
```js
helaTestnet: {
  url: "https://testnet-rpc.helachain.com",
  chainId: 666,
  accounts: [process.env.PRIVATE_KEY]
}
```

---

## 📡 API Reference

Base URL: `http://localhost:8000`

Interactive Docs: http://localhost:8000/api/docs

### Decisions

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/decisions` | List all PDRs (filter by status, symbol) |
| `GET` | `/api/decisions/{id}` | Get single PDR by decision_id |
| `POST` | `/api/agent/analyze` | Trigger agent to analyze a symbol |
| `POST` | `/api/decisions/{id}/approve` | Manually approve a pending decision |
| `POST` | `/api/decisions/{id}/reject` | Manually reject a pending decision |
| `GET` | `/api/verify/{id}` | Run cryptographic verification (level 1/2/3) |

### Challenges & DAO

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/challenges` | Raise a challenge against a decision |
| `GET` | `/api/challenges` | List all challenges |
| `POST` | `/api/challenges/{id}/vote` | Cast a vote (support: true/false) |

### Analytics

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/stats` | Dashboard statistics (totals, averages) |
| `POST` | `/api/flush` | Force-flush Merkle batch to HeLa chain |

### WebSocket

```
WS ws://localhost:8000/ws/feed
```

Real-time events:
- `NEW_DECISION` — New PDR created
- `DECISION_APPROVED` / `DECISION_REJECTED` — Status change
- `CHALLENGE_RAISED` — New challenge raised
- `VOTE_CAST` — Vote recorded
- `BATCH_ANCHORED` — Merkle batch written to HeLa

### Example: Analyze a Stock

```bash
curl -X POST http://localhost:8000/api/agent/analyze \
  -H "Content-Type: application/json" \
  -d '{"symbol": "RELIANCE", "quantity": 10}'
```

---

## 🖥️ Dashboard Guide

Open **http://localhost:7890**

### Page 1 — Overview (Chatbot Landing)
- 📊 **Live Market Ticker** — 11 NSE stocks + ETH/BTC, updating every 8 seconds
- 🤖 **Agent Selector** — Switch between Llama 3, Gemini, GPT-4o, Claude 3.5
- 💬 **AI Chat Interface** — Type any stock/crypto/portfolio question
- ⚡ **Quick Actions** — RELIANCE, TCS, ETH, Portfolio, Audit Trail one-click buttons
- 📈 **Stats Sidebar** — Live decision counts, confidence, HeLa anchors
- 🔄 **Protocol Flow** — Visual pipeline: Agent → PDR → IPFS → Merkle → HeLa → DAO

### Page 2 — Decisions
- Full paginated table of all PDR records
- Filter by: `ALL / PENDING / APPROVED / CHALLENGED / BLOCKED`
- Search by symbol or decision ID
- Click any row to see full PDR JSON with verification status

### Page 3 — Challenges
- Active disputes with 24-hour countdown timer
- Vote interface: Support / Oppose with HELA stake display
- Historical challenge outcomes and reputation impact

### Page 4 — Portfolio
- Donut chart: NSE holdings by sector
- P&L per stock (realized + unrealized)
- Agent decision timeline: which agent made which call
- Risk heatmap: portfolio concentration analysis

### Page 5 — Governance
- DAO status: active proposals and voting power
- Policy registry: current governance rules
- Agent registry: approved agents and their performance

---

## 🤖 Multi-Agent System

### Agent Routing Logic

```
User Reputation Score:
  0–9    → Llama 3 70B (via Groq)     — Free, fast
  10–39  → Gemini 1.5 Pro             — Standard
  40–69  → GPT-4o (OpenAI)           — Advanced
  70+    → Claude 3.5 Sonnet          — Premium (lowest risk tolerance)
```

### Reputation Score Events

| Event | Points |
|---|---|
| Challenge upheld (you were right) | +10 |
| DAO vote cast | +3 |
| Successful analysis | +1 |
| Challenge dismissed (you were wrong) | -5 |

### Supported Chat Commands

| Command | Example |
|---|---|
| Stock analysis | `Analyze RELIANCE` / `Should I buy TCS?` |
| Crypto market | `What is ETH doing today?` / `BTC outlook` |
| Portfolio | `How is my portfolio performing?` / `P&L summary` |
| Mutual Funds | `Top SIP funds` / `HDFC Flexi Cap NAV` |
| Audit trail | `Explain PDR trail` / `Verify decision AAP-001` |

---

## 🔍 Verification System

### Level 1 — Hash Integrity
```python
# Re-compute SHA-256 and compare to stored hash
computed = sha256(json.dumps(pdr_fields, sort_keys=True))
assert computed == pdr["pdr_hash"]
```

### Level 2 — Deterministic Replay
```python
# Re-run agent with same market snapshot
replay_result = agent.analyze(pdr["asset"], pdr["quantity"], timestamp=pdr["timestamp"])
assert replay_result["action"] == pdr["action"]
```

### Level 3 — ZK-SNARK Proof
```bash
# Generate proof
cd zk/
node generate_proof.js --decision-id AAP-20240419-001

# Verify on-chain
npx hardhat run scripts/verify_proof.js --network helaTestnet
```

Circom circuit: `zk/decision.circom` — proves trade decision validity using Groth16 without revealing the agent's internal parameters.

---

## 🗳️ DAO Governance

### How to Raise a Challenge

```bash
curl -X POST http://localhost:8000/api/challenges \
  -H "Content-Type: application/json" \
  -d '{
    "decision_id": "AAP-20240419-001",
    "reason": "Risk score calculation appears incorrect for current volatility",
    "evidence_note": "India VIX at 18.5 warrants higher risk classification",
    "challenger_addr": "0xYourWalletAddress"
  }'
```

### How to Vote

```bash
curl -X POST "http://localhost:8000/api/challenges/ch_AAP-001_0001/vote?support=true&voter=0xYourAddress"
```

### Governance Rules (PolicyRegistry)

Rules stored on-chain in `PolicyRegistry.sol`:
- `min_stake_hela` — Minimum HELA tokens to raise challenge
- `challenge_window_hours` — Voting window duration (default: 24)
- `auto_approve_risk_threshold` — Max risk for auto-approval (default: 0.5)
- `merkle_batch_size` — PDRs per on-chain anchor (default: 10)

---

## 🔭 ELK Observability

### Start ELK Stack (requires Docker)

```bash
docker compose -f docker-compose.elk.yml up -d
```

| Service | URL |
|---|---|
| Elasticsearch | http://localhost:9200 |
| Kibana | http://localhost:5601 |

### Indices Created Automatically

| Index Pattern | Contains |
|---|---|
| `aap_decisions-*` | All PDR records with risk/confidence scores |
| `aap_chat_sessions-*` | Chat session logs with agent routing info |
| `aap_api_logs-*` | REST API request latency and status codes |
| `aap_events-*` | General platform events |

### Suggested Kibana Dashboards
- Agent Decision Rate by Hour
- Risk Score Distribution Heatmap
- API Latency P95/P99
- Challenge Rate vs. Auto-Approval Rate

> **No Docker?** All events fall back to `data/elk_fallback.jsonl` for local analysis.

---

## 📁 Project Structure

```
aap-hela/
├── agent/                     # AI Agent Layer
│   ├── financial_agent.py     # Main LangGraph agent
│   ├── market_data.py         # NSE, Crypto, MF data fetchers
│   ├── multi_agent_orchestrator.py  # LLM routing by reputation
│   ├── asset_types.py         # Asset enum & dataclass
│   └── forecaster.py          # EMA forecasting engine
│
├── backend/                   # FastAPI Backend
│   ├── main.py                # REST + WebSocket server
│   ├── chat_handler.py        # Chat session manager
│   └── user_manager.py        # SQLite reputation system
│
├── protocol/                  # Blockchain & Audit Layer
│   ├── pdr_builder.py         # PDR schema builder
│   ├── pipeline.py            # Full AAP pipeline orchestrator
│   ├── ipfs_client.py         # Pinata IPFS client
│   ├── hela_anchor.py         # HeLa chain interaction
│   ├── merkle_batcher.py      # Merkle tree batching
│   └── elk_shipper.py         # Async ELK event shipper
│
├── contracts/                 # Solidity Smart Contracts
│   ├── AuditAnchor.sol        # Merkle root registry
│   ├── ChallengeRegistry.sol  # DAO dispute management
│   ├── AgentRegistry.sol      # Approved agent registry
│   └── PolicyRegistry.sol     # On-chain governance rules
│
├── verification/              # Verification Modules
│   └── level1_hash.py         # Hash integrity checker
│
├── zk/                        # Zero-Knowledge Proofs
│   └── decision.circom        # Groth16 ZK circuit
│
├── scripts/                   # Hardhat deployment scripts
│   └── deploy.js              # Contract deployer
│
├── dashboard/                 # Frontend
│   ├── index.html             # Main SPA with all pages
│   ├── style.css              # Premium dark theme
│   └── app.js                 # Application logic + ChatEngine
│
├── elk/                       # ELK Configuration
│   └── logstash.conf          # Logstash pipeline
│
├── docker-compose.elk.yml     # ELK Docker stack
├── hardhat.config.js          # Hardhat network config
├── requirements.txt           # Python dependencies
├── .env.example               # Environment template
├── run_demo.py                # Demo agent runner
└── README.md                  # This file
```

---

## 🗺️ Roadmap

| Phase | Status | Feature |
|---|---|---|
| Phase 1 | ✅ Complete | PDR logging, IPFS, HeLa anchoring, 3-level verification |
| Phase 2 | ✅ Complete | Chatbot UI, multi-agent, ELK, forecasting, reputation system |
| Phase 3 | 🔄 Planned | Cross-chain support (Ethereum, Arbitrum, Solana) |
| Phase 4 | 🔄 Planned | Account Abstraction (ERC-4337) for autonomous execution |
| Phase 5 | 🔄 Planned | Decentralized agent marketplace |
| Phase 6 | 🔄 Planned | Federated learning across agent network |
| Phase 7 | 🔄 Planned | Institutional B2B compliance API |

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Commit your changes: `git commit -m "feat: add your feature"`
4. Push to the branch: `git push origin feat/your-feature`
5. Open a Pull Request

### Commit Convention
```
feat:     New feature
fix:      Bug fix
docs:     Documentation change
refactor: Code restructuring
chore:    Build/config update
```

---

## 📄 License

This project is licensed under the **MIT License**.

---

## 🙏 Acknowledgements

- [HeLa Chain](https://helachain.com) — L1 blockchain infrastructure
- [LangGraph](https://langchain-ai.github.io/langgraph/) — Agent orchestration framework
- [Pinata](https://pinata.cloud) — IPFS pinning service
- [Hardhat](https://hardhat.org) — Ethereum development environment
- [Elastic](https://elastic.co) — ELK stack observability

---

<div align="center">

Built with ❤️ on **HeLa Chain** · [GitHub](https://github.com/Ratneshp1122/aap-hela)

</div>
