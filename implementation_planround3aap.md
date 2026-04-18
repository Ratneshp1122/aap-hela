# AAP-HeLa — Phase 2 Upgrade Plan
## Chatbot Landing Page · Multi-Agent · Multi-Asset · Portfolio · ELK

> **Goal**: Transform the current audit-protocol dashboard into a consumer-grade, chatbot-first finance platform with multi-agent support, multi-asset coverage (Equity, Crypto/ETH, Mutual Funds), rich portfolio visualization with future trend forecasting, all backed by ELK-powered observability.

---

## Project State Analysis

### What Already Exists ✅

| Layer | What's Built | Files |
|---|---|---|
| **Agent** | LangGraph pipeline with Gemini 1.5 Pro, 20+ technical indicators, risk scorer | `agent/financial_agent.py`, `indicators.py`, `market_data.py`, `risk_scorer.py` |
| **Backend** | FastAPI REST + WebSocket server, challenge registry, decision feed | `backend/main.py` |
| **Protocol** | IPFS upload, HeLa anchor, Merkle batcher, pre-validator, pipeline | `protocol/pipeline.py`, etc. |
| **Dashboard** | Multi-page SPA (Overview, Decisions, Approval Queue, Challenges, Verify, Portfolio, DAO, Report) | `dashboard/index.html`, `style.css`, `app.js` |
| **Contracts** | `AuditAnchor.sol`, `ChallengeRegistry.sol`, Hardhat config | `contracts/` |

### What Needs to be Built 🔨

1. **Chatbot-first landing page** — replaces static dashboard home with an AI chat interface
2. **Multi-agent orchestrator** — swap/route between Gemini 1.5 Pro, GPT-4o, Claude 3.5, Llama 3 (Groq) based on user's reputation + risk score
3. **ETH/Crypto + Mutual Funds data layer** — extend `market_data.py` and add new asset adapters
4. **Portfolio visualizations** — historical performance charts, future trend forecast (ARIMA/Prophet), allocation donut, P&L timeline
5. **ELK stack integration** — ship all PDR events, agent decisions, and API logs to Elasticsearch → Kibana

---

## User Review Required

> [!IMPORTANT]
> **Agent API Keys**: Integrating GPT-4o requires an `OPENAI_API_KEY`, Claude requires `ANTHROPIC_API_KEY`, Groq (Llama) requires `GROQ_API_KEY`. You will need to supply these. The plan will add them to `.env.example` with the agent routing logic.

> [!IMPORTANT]
> **Crypto Data Source**: For ETH/crypto live prices, the plan uses CoinGecko free API (no key needed for basic use) and CoinMarketCap (free tier key). Mutual Funds data will use MFAPI.in (India-specific, free). Please confirm if you want real-time paid feeds (e.g., CoinGecko Pro, Alpha Vantage).

> [!WARNING]
> **ELK Stack**: Running a full local ELK stack (Elasticsearch + Logstash + Kibana) requires Docker and ~4GB RAM. The plan will add a `docker-compose.elk.yml` for easy local setup. Alternatively, we can use Elastic Cloud free tier — please confirm.

> [!NOTE]
> **Prophet/ARIMA Forecasting**: Adding `prophet` or `statsmodels` (ARIMA) as Python dependencies for portfolio trend forecasting. These add ~200MB to the Python environment. Confirm if you want this. Alternatively, a simpler exponential moving average (EMA) forecast can be used.

---

## Architecture Overview (After Upgrade)

```
┌─────────────────────────────────────────────────────┐
│              CHATBOT LANDING PAGE (New)              │
│  - AI chat interface (center)                        │
│  - Agent selector (reputation/risk gated)            │
│  - Live portfolio summary sidebar                     │
│  - Real-time market ticker                           │
└───────────────────────┬─────────────────────────────┘
                        │ REST + WebSocket
                        ▼
┌─────────────────────────────────────────────────────┐
│           FastAPI Backend (Extended)                 │
│  NEW: /api/chat      — chatbot endpoint              │
│  NEW: /api/agents    — list available agents         │
│  NEW: /api/portfolio — full portfolio API            │
│  NEW: /api/crypto    — ETH/crypto prices             │
│  NEW: /api/mf        — mutual fund NAV data          │
│  NEW: /api/forecast  — ML trend prediction           │
└──────────┬────────────────────┬──────────────────────┘
           │                    │
    ┌──────▼──────┐    ┌────────▼────────┐
    │ Multi-Agent │    │   ELK Stack     │
    │ Orchestrator│    │  Elasticsearch  │
    │ (New)       │    │  Logstash       │
    │             │    │  Kibana         │
    │ • Gemini    │    └─────────────────┘
    │ • GPT-4o    │
    │ • Claude    │
    │ • Llama3    │
    └─────────────┘
```

---

## Proposed Changes

### 1. Chatbot Landing Page

#### [MODIFY] `dashboard/index.html`
- Convert the `page-overview` section into a **chatbot-first landing experience**
- Add a prominent AI chat panel (center, full-height) with:
  - Animated message bubbles
  - Agent selector dropdown (gated by reputation/risk score)
  - Context cards for portfolio summary, market pulse
- Keep the existing sidebar navigation for power-user pages

#### [MODIFY] `dashboard/style.css`
- Add chatbot component styles: message bubbles, agent avatar chips, typing indicator
- Add agent selector chip styles with reputation badge

#### [MODIFY] `dashboard/app.js`
- Add `ChatEngine` class that POSTs to `/api/chat`
- Handle streaming responses via SSE or chunked WebSocket
- Render markdown responses from agents

---

### 2. Multi-Agent Orchestrator

The core idea: each user has a **reputation score** (0–100, based on past challenge accuracy, governance participation) and a **risk score** (0.0–1.0, from the existing `RiskScorer`). Different agents are unlocked based on these:

| Agent | Min Reputation | Max Risk Score Allowed | Use Case |
|---|---|---|---|
| **Llama 3 (Groq)** | 0 | 1.0 | All users — fast, free-tier |
| **Gemini 1.5 Pro** | 10 | 0.7 | Standard users |
| **GPT-4o** | 40 | 0.5 | Experienced users |
| **Claude 3.5 Sonnet** | 70 | 0.3 | High-trust, low-risk users |

#### [NEW] `agent/multi_agent_orchestrator.py`
```python
class AgentOrchestrator:
    AGENTS = {
        "llama3":   {"min_rep": 0,  "max_risk": 1.0, "model": "llama3-70b-8192", "provider": "groq"},
        "gemini":   {"min_rep": 10, "max_risk": 0.7, "model": "gemini-1.5-pro",  "provider": "google"},
        "gpt4o":    {"min_rep": 40, "max_risk": 0.5, "model": "gpt-4o",          "provider": "openai"},
        "claude":   {"min_rep": 70, "max_risk": 0.3, "model": "claude-3-5-sonnet-20241022", "provider": "anthropic"},
    }
    
    def get_available_agents(self, user_reputation: int, user_risk_score: float) -> list
    def route(self, agent_id: str, prompt: str, context: dict) -> Generator[str, None, None]
    def chat(self, message: str, agent_id: str, session_id: str) -> str
```

#### [MODIFY] `agent/financial_agent.py`
- Extract LLM call into a provider-agnostic `call_llm(provider, model, prompt)` function
- Support OpenAI, Anthropic, Google, Groq SDK calls

#### [MODIFY] `.env.example`
- Add: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GROQ_API_KEY`
- Add: `DEFAULT_AGENT=gemini`

---

### 3. Multi-Asset Data Layer (ETH, Crypto, Mutual Funds)

#### [MODIFY] `agent/market_data.py`
- Add `CryptoData` class:
  - `get_eth_price()` — CoinGecko API
  - `get_crypto_history(symbol, days)` — BTC, ETH, SOL, BNB, MATIC
  - `get_crypto_portfolio_value(holdings: dict) -> float`
- Add `MutualFundData` class:
  - `get_fund_nav(scheme_code)` — MFAPI.in
  - `get_fund_history(scheme_code, days)` — Historical NAV
  - `get_popular_funds()` — Top SIP funds

#### [NEW] `agent/asset_types.py`
- `AssetType` enum: `EQUITY`, `CRYPTO`, `ETH`, `MUTUAL_FUND`
- `Asset` dataclass with type-aware price fetching
- Unified `get_price(asset: Asset)` dispatcher

---

### 4. Portfolio Visualization + Forecasting

#### [MODIFY] `backend/main.py`
- Add `/api/portfolio` endpoint returning unified portfolio across all asset classes
- Add `/api/portfolio/history` — 30/90/365 day performance
- Add `/api/forecast/{symbol}` — ML-based price forecast (returns 7/30 day prediction + confidence intervals)
- Add `/api/crypto/prices` — real-time crypto prices
- Add `/api/mf/nav` — mutual fund NAV lookup
- Add `/api/chat` — chatbot endpoint with SSE streaming

#### [NEW] `agent/forecaster.py`
- `ForecastEngine` class using **Prophet** (or fallback to EMA if Prophet unavailable)
- `forecast(symbol, asset_type, horizon_days=30)` → returns `{dates, predicted_prices, upper_bound, lower_bound}`
- Trend direction: `BULLISH`, `BEARISH`, `SIDEWAYS`

#### [MODIFY] `dashboard/index.html`
- Portfolio page (`page-portfolio`) upgrades:
  - **Asset class tabs**: Equity | Crypto | ETH | Mutual Funds
  - **Combined portfolio value** with cross-asset allocation donut
  - **Historical performance chart** (line chart, Chart.js or Recharts CDN)
  - **Future trend forecast panel** — dotted projection line with confidence band
  - **P&L timeline** — area chart
  - **Risk heatmap** — per position risk score color matrix

---

### 5. ELK Stack Integration

#### [NEW] `docker-compose.elk.yml`
```yaml
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.13.0
    ports: ["9200:9200"]
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
  
  logstash:
    image: docker.elastic.co/logstash/logstash:8.13.0
    volumes:
      - ./elk/logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    ports: ["5044:5044", "9600:9600"]
  
  kibana:
    image: docker.elastic.co/kibana/kibana:8.13.0
    ports: ["5601:5601"]
    depends_on: [elasticsearch]
```

#### [NEW] `elk/logstash.conf`
- Ingest pipeline: `aap_decisions` index for PDRs
- Fields: `decision_id`, `asset`, `action`, `risk_score`, `confidence`, `agent_model`, `timestamp`
- Filter: parse JSON, add geo-ip, compute duration

#### [NEW] `protocol/elk_shipper.py`
```python
class ELKShipper:
    def ship_pdr(self, pdr: dict) -> None  # → Elasticsearch aap_decisions index
    def ship_chat_event(self, event: dict) -> None  # → aap_chat_sessions index
    def ship_api_log(self, request, response, duration_ms) -> None  # → aap_api_logs index
```

#### [MODIFY] `protocol/pipeline.py`
- After every PDR is processed, call `ELKShipper.ship_pdr(pdr)` asynchronously

#### [MODIFY] `backend/main.py`
- Add ELK middleware for API request/response logging
- Add `/api/kibana-redirect` endpoint linking to Kibana dashboard

#### [NEW] `elk/kibana_dashboards/aap_overview.ndjson`
- Pre-built Kibana dashboard export:
  - Decisions over time (area chart)
  - Risk score distribution (histogram)
  - Agent model usage (pie chart)
  - Live decision feed (data table)
  - Challenge rate (gauge)

---

### 6. Backend API Extensions

#### [MODIFY] `backend/main.py`

New endpoints:

```
POST /api/chat                    — Chatbot (SSE streaming)
GET  /api/agents                  — List all agents + availability per user
GET  /api/agents/{id}/status      — Agent health check
GET  /api/portfolio               — Unified portfolio (all asset classes)
GET  /api/portfolio/history       — Historical performance
GET  /api/portfolio/allocation    — Asset class breakdown
GET  /api/forecast/{symbol}       — ML-based trend prediction
GET  /api/crypto/prices           — Live crypto prices
GET  /api/crypto/history/{symbol} — Crypto price history
GET  /api/mf/nav/{scheme_code}    — Mutual fund NAV
GET  /api/mf/search               — Search funds
GET  /api/user/reputation         — User reputation score
GET  /api/user/risk-profile       — User risk profile
```

#### [NEW] `backend/chat_handler.py`
- `ChatHandler` class that routes messages to the correct LLM agent
- Maintains conversation memory per `session_id` (in-memory, Redis later)
- Formats agent responses with financial context (prices, portfolio, decisions)

#### [NEW] `backend/user_manager.py`
- `UserManager` for reputation scoring:
  - Score increases when challenges are upheld
  - Score decreases when challenges are dismissed
  - Score increases with DAO governance participation
  - Stored in SQLite for MVP, PostgreSQL for production

---

### 7. Environment + Dependencies

#### [MODIFY] `.env.example`
Add new keys:
```bash
# Multi-Agent LLMs
OPENAI_API_KEY=your_openai_key
ANTHROPIC_API_KEY=your_anthropic_key
GROQ_API_KEY=your_groq_key
DEFAULT_AGENT=gemini

# Crypto Data
COINGECKO_API_KEY=optional_pro_key
CMC_API_KEY=your_cmc_key

# ELK Stack
ELASTICSEARCH_URL=http://localhost:9200
KIBANA_URL=http://localhost:5601
ELK_INDEX_PREFIX=aap
```

#### [MODIFY] `requirements.txt`
Add:
```
# Multi-agent LLMs
openai>=1.30.0
anthropic>=0.30.0
groq>=0.9.0

# Forecasting
prophet>=1.1.5
statsmodels>=0.14.0

# ELK
elasticsearch>=8.13.0

# APIs
ccxt>=4.3.0          # crypto exchange data
requests>=2.31.0

# Streaming
sse-starlette>=1.8.0  # Server-Sent Events for streaming chat
```

---

## File Change Summary

| File | Action | Description |
|---|---|---|
| `dashboard/index.html` | MODIFY | Chatbot landing page, multi-asset portfolio tabs, forecast charts |
| `dashboard/style.css` | MODIFY | Chat component styles, agent chips, chart containers |
| `dashboard/app.js` | MODIFY | ChatEngine, streaming SSE handler, Chart.js integration |
| `agent/multi_agent_orchestrator.py` | NEW | Multi-LLM routing with reputation/risk gating |
| `agent/financial_agent.py` | MODIFY | Provider-agnostic LLM call, multi-asset support |
| `agent/market_data.py` | MODIFY | Add CryptoData, MutualFundData classes |
| `agent/asset_types.py` | NEW | AssetType enum, unified Asset dataclass |
| `agent/forecaster.py` | NEW | Prophet/EMA forecasting engine |
| `backend/main.py` | MODIFY | New chat, agent, portfolio, crypto, MF, forecast endpoints |
| `backend/chat_handler.py` | NEW | Chatbot session handler with memory |
| `backend/user_manager.py` | NEW | Reputation score tracker |
| `protocol/elk_shipper.py` | NEW | Elasticsearch document shipper |
| `protocol/pipeline.py` | MODIFY | Hook ELKShipper into PDR processing |
| `.env.example` | MODIFY | Add LLM keys, crypto API keys, ELK config |
| `requirements.txt` | MODIFY | Add openai, anthropic, groq, prophet, elasticsearch, ccxt |
| `docker-compose.elk.yml` | NEW | Full ELK stack docker-compose |
| `elk/logstash.conf` | NEW | Logstash pipeline config |
| `elk/kibana_dashboards/aap_overview.ndjson` | NEW | Pre-built Kibana dashboard |

---

## Open Questions

> [!IMPORTANT]
> **Q1 — Agent Model Costs**: GPT-4o and Claude 3.5 are not free. The gating by reputation score helps limit usage to trusted users, but confirm: should there be a **hard daily token budget** per user? Or rely purely on rep/risk gating?

> [!IMPORTANT]
> **Q2 — ELK Self-hosted vs Cloud**: Running ELK locally via Docker is simpler but heavy. Elastic Cloud free tier gives 14 days. Do you want local Docker ELK or cloud? This affects the `elk_shipper.py` auth config.

> [!NOTE]
> **Q3 — Crypto Portfolio**: Should ETH/Crypto be **live connected to a wallet address** (read-only via RPC), or **manually entered holdings** for MVP?

> [!NOTE]
> **Q4 — Mutual Funds**: India MFAPI.in is used for MF data. Should this also support **Zerodha Coin** integration via their API, or is MFAPI sufficient?

> [!NOTE]
> **Q5 — Chatbot Persona**: Should the chatbot have a named persona (e.g., "ADAPT AI"), or remain a generic assistant interface? It affects the landing page hero design.

---

## Verification Plan

### Automated Tests
```bash
# Backend API
pytest tests/test_chat_endpoint.py -v
pytest tests/test_multi_agent.py -v
pytest tests/test_crypto_data.py -v
pytest tests/test_forecast.py -v

# ELK integration
pytest tests/test_elk_shipper.py -v

# Full E2E
npx playwright test e2e/chatbot_flow.spec.ts
npx playwright test e2e/portfolio_viz.spec.ts

# ELK stack health
curl http://localhost:9200/_cluster/health
curl http://localhost:5601/api/status
```

### Manual Verification
1. Open landing page → verify chatbot interface renders
2. Select different agents from dropdown → verify gating works
3. Ask "Analyze RELIANCE" → verify agent response streams in real-time
4. Navigate to Portfolio → verify all asset class tabs (Equity, Crypto, MF)
5. Check forecast chart — trend line should appear for selected symbol
6. Run an analysis → verify PDR appears in Kibana within 5s
