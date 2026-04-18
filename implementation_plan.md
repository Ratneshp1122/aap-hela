# ADAPT — Autonomous Decision Audit & Proof Transparency Protocol

> **Core Mission:** Every autonomous agent decision must be explainable, challengeable,
> verifiable, and tamper-proof — by design, not by afterthought.

---

## 1. Abstract — What Is This?

**ADAPT** is a protocol layer that sits *between* an autonomous agent's reasoning engine and
its execution environment. Before any action reaches the blockchain or external system, ADAPT:

1. **Intercepts** the decision as a structured record
2. **Explains** it in human-readable, traceable language
3. **Commits** it to an immutable, tamper-proof audit chain
4. **Gates** it through a challenge window before execution
5. **Allows override** by users or DAOs if the decision is contested

It is chain-agnostic, agent-framework-agnostic, and scales from a single agent on a local
machine to a swarm of thousands across multiple blockchains.

---

## 2. The Core Problem (Detailed)

| Failure Mode | Real-World Risk | Root Cause |
|---|---|---|
| Agent takes an action — no one knows *why* | Unaccountable automation in governance | No structured reasoning log |
| Log exists but can be altered by operator | False audit trails | Mutable, centralized storage |
| Decision can't be independently verified | No trustless auditability | No cryptographic proof linking decision → action |
| Human can't parse the transaction calldata | WYSIWYS failure | No translation layer |
| Bad decisions can't be stopped | Irreversible harm | No pre-execution challenge window |
| One bad agent can corrupt an entire workflow | Cascading failure | No independent verifier in the pipeline |

---

## 3. Protocol Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AGENT RUNTIME                            │
│  (LangGraph / CrewAI / Custom)                                  │
└──────────────────────┬──────────────────────────────────────────┘
                       │ Decision Output (raw)
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│              ADAPT MIDDLEWARE (Off-Chain)                        │
│                                                                  │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │  DRS Builder│→ │  Explainer   │→ │  Merkle Batcher      │   │
│  │  (Schema)   │  │  (CoT + NL)  │  │  (IPFS + Root Hash)  │   │
│  └─────────────┘  └──────────────┘  └──────────┬───────────┘   │
└──────────────────────────────────────────────────┼──────────────┘
                                                   │ Merkle Root
                                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│              ON-CHAIN LAYER (Base / Arbitrum L2)                 │
│                                                                  │
│  ┌─────────────────┐    ┌──────────────────────────────────┐   │
│  │  AuditAnchor.sol│    │  ChallengeRegistry.sol            │   │
│  │  - anchorRoot() │    │  - raiseChallenge(decisionId)     │   │
│  │  - verifyLeaf() │    │  - voteOnChallenge(id, support)   │   │
│  └─────────────────┘    │  - executeOverride(id)            │   │
│                          │  - executeCancel(id)              │   │
│                          └──────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                  FRONTEND DASHBOARD (Next.js)                    │
│  - Live decision feed (human-readable)                           │
│  - Challenge button per decision                                 │
│  - DAO vote panel                                                │
│  - Merkle proof verifier widget                                  │
│  - Kill Switch                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. The Decision Record Schema (DRS)

Every agent decision is encoded as a **Decision Record** — a signed, structured JSON-LD
document. This is the atomic unit of the entire protocol.

```jsonc
{
  "@context": "https://adapt-protocol.org/schema/v1",
  "@type": "DecisionRecord",

  // === IDENTITY ===
  "decision_id": "dr_3f7a2c...b91e",          // UUID v4, globally unique
  "agent_did": "did:ethr:0xABCD...1234",       // W3C DID of the acting agent
  "session_id": "sess_8d2b...",               // current agent session
  "timestamp_iso": "2026-04-18T13:05:00Z",
  "sequence_number": 142,                      // monotonic counter per agent

  // === CONTEXT (What the agent saw) ===
  "input_context": {
    "goal": "Process governance proposal #47 for DAO treasury",
    "retrieved_data_cids": ["Qm3x...", "Qm9y..."],  // IPFS CIDs of RAG data used
    "system_prompt_hash": "sha256:4a8f...",          // hash of system prompt version
    "model_version": "gpt-4o-2025-04",
    "temperature": 0.2
  },

  // === REASONING (Why the agent decided) ===
  "reasoning_chain": [
    {
      "step": 1,
      "thought": "The proposal requests 50,000 USDC allocation to dev fund.",
      "evidence_cid": "Qm1a..."
    },
    {
      "step": 2,
      "thought": "Current treasury balance is 2.1M USDC. Allocation is 2.4% — within the 5% single-action limit.",
      "evidence_cid": "Qm2b..."
    },
    {
      "step": 3,
      "thought": "Proposer reputation score: 94/100. No prior disputes. Rule: trust_threshold = 80. Condition satisfied.",
      "evidence_cid": null
    }
  ],

  // === DECISION (What the agent chose) ===
  "decision": {
    "action_type": "APPROVE_PROPOSAL",
    "action_target": "0xDAOContract...5678",
    "parameters": { "proposal_id": 47, "vote": "FOR" },
    "confidence_score": 0.91,
    "alternative_actions_considered": ["ABSTAIN", "REJECT"],
    "policy_rule_applied": "governance_policy_v3::quorum_check"
  },

  // === OUTCOME (What actually happened) ===
  "execution_status": "PENDING_CHALLENGE",   // PENDING | EXECUTED | OVERRIDDEN | CANCELLED
  "tx_hash": null,                           // filled after execution
  "simulation_result_cid": "Qm7c...",       // Tenderly sim result stored on IPFS

  // === EXPLAINABILITY (Human-readable) ===
  "human_explanation": "The agent voted FOR proposal #47 because the requested amount (50,000 USDC) is within the approved daily spend limit, the proposer has a high trust score (94/100), and the treasury balance is sufficient. Two alternatives (ABSTAIN, REJECT) were considered but rejected as the policy conditions were fully satisfied.",

  // === TAMPER-PROOF ANCHORS ===
  "prev_record_hash": "sha256:8b3d...",      // hash of previous DRS — forms a chain
  "record_hash": "sha256:f9e1...",           // sha256 of this entire record (minus this field)
  "agent_signature": "0x...",               // agent signs with its DID-bound key
  "ipfs_cid": "QmDRS..."                    // CID of this record stored on IPFS
}
```

---

## 5. Tamper-Proof Storage — Merkle Batch Anchoring

Logging every decision individually on-chain is expensive at scale. Instead:

```
Every N decisions (or every T seconds, whichever comes first):

DRS[0]  DRS[1]  DRS[2] ... DRS[N]
  │       │       │           │
sha256  sha256  sha256     sha256
  └───────┴───┐  └──────────┘
          sha256            sha256
              └────────────────┘
                   Merkle Root
                       │
              anchorRoot(root, blockNumber)
              → stored in AuditAnchor.sol (gas: ~21,000)
              → emits: RootAnchored(root, timestamp, agentDid)
```

**Storage breakdown:**

| Layer | What | Storage | Cost |
|---|---|---|---|
| Full DRS payload | Complete decision record | IPFS (Filebase pinning) | ~$0.01/GB/month |
| Reasoning CoT | Chain-of-thought steps | IPFS | same |
| Merkle Root | 32-byte hash | On-chain (Base L2) | ~$0.002 per batch |
| CID index | IPFS CID per record | SQLite off-chain index | negligible |

**Why this is tamper-proof:**
- Any edit to a DRS changes its sha256 hash → invalidates the Merkle Root → the on-chain root no longer matches → tampering is cryptographically detectable
- The Merkle proof for any specific record can be independently verified by anyone with the root (from chain) and the leaf (from IPFS)

---

## 6. On-Chain Contracts — Interface Design

### 6.1 `AuditAnchor.sol`
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract AuditAnchor {
    struct AnchorRecord {
        bytes32 merkleRoot;
        uint256 timestamp;
        address agentAddress;
        uint256 batchSize;
        string ipfsIndexCid;    // CID pointing to the batch index on IPFS
    }

    // agentAddress → array of anchors
    mapping(address => AnchorRecord[]) public anchors;

    event RootAnchored(
        bytes32 indexed merkleRoot,
        address indexed agent,
        uint256 timestamp,
        uint256 batchSize
    );

    function anchorRoot(
        bytes32 merkleRoot,
        uint256 batchSize,
        string calldata ipfsIndexCid
    ) external {
        anchors[msg.sender].push(AnchorRecord({
            merkleRoot: merkleRoot,
            timestamp: block.timestamp,
            agentAddress: msg.sender,
            batchSize: batchSize,
            ipfsIndexCid: ipfsIndexCid
        }));
        emit RootAnchored(merkleRoot, msg.sender, block.timestamp, batchSize);
    }

    function verifyLeaf(
        address agent,
        uint256 anchorIndex,
        bytes32 leaf,
        bytes32[] calldata proof
    ) external view returns (bool) {
        bytes32 root = anchors[agent][anchorIndex].merkleRoot;
        return MerkleProof.verify(proof, root, leaf);
    }
}
```

### 6.2 `ChallengeRegistry.sol` (Simplified)
```solidity
contract ChallengeRegistry {
    enum ChallengeStatus { OPEN, UPHELD, DISMISSED, EXECUTED }

    struct Challenge {
        string  decisionId;          // maps to DRS decision_id
        bytes32 recordHash;          // the DRS record_hash being contested
        address challenger;
        uint256 raisedAt;
        uint256 votesFor;            // votes to override/cancel
        uint256 votesAgainst;
        ChallengeStatus status;
        string  reason;
    }

    uint256 public constant CHALLENGE_WINDOW = 15 minutes;
    uint256 public constant VOTING_PERIOD    = 48 hours;

    mapping(string => Challenge) public challenges;

    event ChallengeRaised(string decisionId, address challenger, string reason);
    event ChallengeClosed(string decisionId, ChallengeStatus status);

    function raiseChallenge(
        string calldata decisionId,
        bytes32 recordHash,
        string calldata reason
    ) external {
        // Only during challenge window (pre-execution)
        challenges[decisionId] = Challenge({
            decisionId:   decisionId,
            recordHash:   recordHash,
            challenger:   msg.sender,
            raisedAt:     block.timestamp,
            votesFor:     0,
            votesAgainst: 0,
            status:       ChallengeStatus.OPEN,
            reason:       reason
        });
        emit ChallengeRaised(decisionId, msg.sender, reason);
    }

    function voteOnChallenge(string calldata decisionId, bool support) external {
        Challenge storage c = challenges[decisionId];
        require(c.status == ChallengeStatus.OPEN, "Not open");
        require(block.timestamp < c.raisedAt + VOTING_PERIOD, "Voting ended");
        if (support) c.votesFor += 1;
        else         c.votesAgainst += 1;
    }

    function resolveChallenge(string calldata decisionId) external {
        Challenge storage c = challenges[decisionId];
        require(block.timestamp >= c.raisedAt + VOTING_PERIOD, "Still voting");
        c.status = (c.votesFor > c.votesAgainst)
            ? ChallengeStatus.UPHELD     // decision overridden
            : ChallengeStatus.DISMISSED; // decision proceeds
        emit ChallengeClosed(decisionId, c.status);
    }
}
```

---

## 7. Explainability Engine

The Explainability Engine runs off-chain, alongside the agent. It has three outputs per decision:

### 7.1 Structured Reason Codes
Machine-readable, standardized for automated monitoring:
```
APPROVED::WITHIN_SPEND_LIMIT + PROPOSER_TRUST_SCORE_OK + SIMULATION_PASSED
REJECTED::EXCEEDED_DAILY_CAP
DEFERRED::INSUFFICIENT_CONTEXT_DATA
OVERRIDDEN::HUMAN_VETO_RECEIVED
```

### 7.2 Natural Language Summary (LLM-generated)
The agent's LLM produces a plain-English explanation as part of its output schema.
This is **not post-hoc rationalization** — the explanation is generated *simultaneously*
with the decision, ensuring it reflects the actual reasoning path.
```
"The agent voted FOR proposal #47 because the requested amount (50,000 USDC)
is within the approved daily spend limit, the proposer has a high trust score
(94/100), and the treasury balance is sufficient. Two alternatives (ABSTAIN,
REJECT) were considered but rejected as the policy conditions were fully satisfied."
```

### 7.3 WYSIWYS Calldata Decoder
For decisions that result in on-chain transactions, the frontend decodes the raw calldata
into a human-readable table:

| Field | Value |
|---|---|
| Function | `vote(uint256 proposalId, uint8 support)` |
| Proposal ID | 47 |
| Vote | FOR (1) |
| Gas Estimate | 85,000 units (~$0.04 on Base) |
| Predicted State Change | Treasury -0 USDC; Proposal 47 vote count +1 |
| Simulation | ✅ Passed (no unexpected token transfers) |

---

## 8. Proposer → Verifier → Executor Audit Triad

The multi-agent structure that ensures no single agent decision reaches execution unchallenged:

```
┌─────────────────────────────────────────────────────────────┐
│                   PROPOSER AGENT                            │
│  - Generates decision + DRS                                  │
│  - Runs Explainability Engine                                │
│  - Submits DRS to IPFS                                       │
│  - Notifies Verifier                                         │
└──────────────────────────┬──────────────────────────────────┘
                           │ DRS + IPFS CID
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   VERIFIER AGENT (independent)               │
│  CHECKS:                                                     │
│  ✓ DRS schema validity                                       │
│  ✓ Agent signature valid (DID verification)                  │
│  ✓ Retrieved data CIDs resolve and match hash                │
│  ✓ Policy rules were correctly applied                       │
│  ✓ Simulation result is consistent with claimed outcome      │
│  ✓ prev_record_hash matches last anchored record             │
│                                                              │
│  OUTPUT: "VERIFY_OK" or "VERIFY_FAIL::REASON_CODE"          │
└──────────────────────────┬──────────────────────────────────┘
                           │ If VERIFY_OK
                           ▼
┌─────────────────────────────────────────────────────────────┐
│            CHALLENGE WINDOW (15 min, configurable)           │
│  - Human users / DAO members can call raiseChallenge()       │
│  - Frontend shows WYSIWYS preview with [CHALLENGE] button    │
│  - If no challenge: execution proceeds automatically         │
│  - If challenge raised: 48hr DAO vote to override or dismiss │
└──────────────────────────┬──────────────────────────────────┘
                           │ If no challenge / challenge dismissed
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   EXECUTOR AGENT                             │
│  - Signs + submits the UserOperation (ERC-4337)              │
│  - Fills in tx_hash in the DRS                               │
│  - Triggers Merkle Batcher to include this DRS in next batch │
│  - Updates execution_status to "EXECUTED"                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 9. Prototype Flow (Concrete, End-to-End)

**Scenario: A governance agent votes on a DAO proposal**

```
Step 1 — Agent decides
  ProposerAgent.run(goal="Vote on proposal #47")
  → LangGraph produces: action=VOTE_FOR, reasoning=[step1, step2, step3]
  → Explainability Engine generates: human_explanation + reason_codes
  → DRS Builder assembles the Decision Record JSON
  → DRS is hashed: record_hash = sha256(DRS)
  → Agent signs: signature = agent_key.sign(record_hash)

Step 2 — Log to IPFS
  ipfs.add(DRS) → returns ipfs_cid = "QmDRS7x..."
  ipfs.add(simulation_result) → returns "QmSim9y..."
  Both CIDs written into the DRS before final hashing

Step 3 — Verifier checks
  VerifierAgent.fetch(ipfs_cid)
  → Validates schema ✓
  → Resolves all retrieved_data_cids → content matches expected hash ✓
  → Re-runs policy check with same inputs → gets same APPROVE result ✓
  → Checks prev_record_hash matches last known anchor ✓
  → Signs: verifier_approval = verifier_key.sign(record_hash)

Step 4 — On-chain: Challenge window opens
  Frontend emits: DecisionPending(decisionId, ipfsCid, humanExplanation)
  Push Protocol notification → all subscribed DAO members see:
  "Agent voted FOR proposal #47. Reason: [expand]. [CHALLENGE] [OK]"
  15-minute window begins.

Step 5a — No challenge: Auto-execute
  After 15 min: ExecutorAgent.execute(UserOperation)
  → tx_hash returned from Base L2
  → DRS updated: execution_status = "EXECUTED", tx_hash = "0x..."
  → DRS added to Merkle batch

Step 5b — Challenge raised:
  User calls: ChallengeRegistry.raiseChallenge(decisionId, hash, reason)
  → 48hr voting period starts
  → DAO members call voteOnChallenge(decisionId, true/false)
  → After 48hr: resolveChallenge(decisionId)
    IF UPHELD → execution_status = "OVERRIDDEN" → action cancelled
    IF DISMISSED → ExecutorAgent.execute() proceeds

Step 6 — Batch anchor
  Every 100 DRS records (or every 10 min):
  MerkleBatcher.buildTree([drHash0, drHash1, ... drHash99])
  → root = merkleTree.getRoot()
  → AuditAnchor.anchorRoot(root, 100, batchIpfsCid)
  → Gas cost: ~$0.002 on Base L2
```

---

## 10. Scalability Design

| Challenge | Solution | Details |
|---|---|---|
| High-frequency agents (1000s of decisions/min) | Merkle batch anchoring | Only 1 on-chain tx per batch, not per decision |
| Large reasoning traces | IPFS off-chain | On-chain stores only 32-byte hash |
| Multiple agents in parallel | Agent DID namespacing | Each agent has its own anchor history |
| Cross-agent verification | Shared verifier pool | Verifier agents are stateless; horizontally scalable |
| Challenge spam | Bond requirement | Challengers stake a small bond; returned if upheld, burned if dismissed |
| IPFS data availability | Filecoin + Arweave pinning | Long-term persistence guaranteed |

---

## 11. Tech Stack (Feasible Only)

| Layer | Technology | Why Feasible |
|---|---|---|
| **Agent Framework** | LangGraph (Python) | Mature, production-ready stateful agent orchestration |
| **LLM** | OpenAI GPT-4o / Anthropic Claude (API) | Standard API, plug-and-play for CoT generation |
| **DRS Schema** | JSON-LD + Python `jsonschema` | Generate, validate, and sign records in pure Python |
| **Cryptographic Signing** | `eth_account` (Python) / `viem` (JS) | Standard EVM signing, no exotic dependencies |
| **IPFS** | `ipfshttpclient` Python lib + Filebase (managed) | No self-hosted node needed for MVP |
| **Merkle Trees** | `merkletools` (Python) | Lightweight, auditable, well-documented |
| **Smart Contracts** | Solidity 0.8 + Hardhat/Foundry | Standard EVM toolchain, large community |
| **Blockchain** | Base Sepolia (testnet) → Base mainnet | Low gas, EVM-compatible, Coinbase-backed reliability |
| **ERC-4337 Wallet** | ZeroDev SDK | Managed AA — no need to run own bundler |
| **Frontend** | Next.js 14 + TypeScript + Wagmi/Viem | Industry standard Web3 frontend stack |
| **Embedded Wallet** | Privy | Social login + embedded wallet, no seed phrase UX friction |
| **Notifications** | Push Protocol (PUSH) | Decentralized real-time alerts to DAO members |
| **Simulation** | Tenderly Virtual TestNets API | REST API, no infrastructure setup |
| **Policy Engine** | OPA (Open Policy Agent) + Rego | Single binary, very fast, proven in production |
| **Vector DB / RAG** | ChromaDB (local) | Lightweight, self-contained, no cloud dependency for MVP |
| **Kill Switch** | Solidity `Pausable` (OpenZeppelin) | One-line integration, battle-tested |

**Explicitly excluded (not feasible for prototype):**
- ~~zkML (EZKL)~~ — proof times too slow for high-frequency decisions at prototype stage
- ~~TEE Attestation Marketplace~~ — requires hardware infrastructure
- ~~Intent Futures Market~~ — requires a live market with participants
- ~~Cross-chain DID Bridge~~ — significantly increases deployment complexity; add in Phase 3+

---

## 12. Feasible Innovations (Implementable Now)

### ✅ 1. Linked-Record Hash Chain
Each DRS contains the `prev_record_hash` of the prior record. This forms a singly-linked chain that makes **record insertion or deletion attacks immediately detectable** — same principle as a blockchain, but for agent decision history. Anyone can walk the chain from genesis to verify no gaps or insertions. Implementation: 1 extra field in the schema + 1 check in the Verifier agent.

### ✅ 2. Challenger Bond Staking
Anyone raising a challenge must stake a small bond (e.g., 5 USDC). If the challenge is upheld (vote passes), the bond is returned + a reward from a governance treasury. If dismissed, the bond is burned. This **prevents spam challenges** while incentivizing legitimate whistleblowers. Implementation: Add `bond` mapping to `ChallengeRegistry.sol` + a simple ERC-20 transfer.

### ✅ 3. Verifier Agent Rotation
The Verifier agent is not fixed — it is randomly selected from a permissioned pool each time. Selection uses the block hash as a seed (VRF-lite). This prevents collusion between a Proposer and a specific Verifier. Implementation: On-chain `selectVerifier(poolAddress[], blockHash)` function — ~20 lines of Solidity.

### ✅ 4. Anomaly Scoring (On-Chain Flag)
Each DRS includes a `confidence_score` from the agent. A simple on-chain rule: if confidence_score < 0.70, the challenge window is automatically extended from 15 minutes to 2 hours, and DAO members get an elevated-priority notification. This creates **automatic scrutiny for uncertain decisions** without requiring continuous human monitoring. Implementation: single `if` in the anchor contract.

### ✅ 5. Audit Explorer (Frontend Widget)
A publicly accessible, read-only web page where anyone can paste a `decision_id` or `agent_did` and see the full audit trail: DRS payload, IPFS links, Merkle proof verification result, challenge history, and final execution status, all fetched from IPFS + on-chain events. No backend required — runs entirely from public IPFS gateways + RPC calls. Implementation: pure Next.js, ~300 lines.

---

## 13. Phased Delivery Roadmap

### Phase 0 — Local Prototype (2–3 weeks)
- [ ] Define and implement DRS JSON-LD schema with Python validator
- [ ] Build `DRSBuilder` class that wraps any LangGraph agent output
- [ ] Implement `ExplainabilityEngine` (CoT extraction + NL summary via GPT-4o API)
- [ ] Implement `MerkleBatcher` using `merkletools`
- [ ] Write and test `AuditAnchor.sol` + `ChallengeRegistry.sol` with Hardhat
- [ ] Upload DRS to IPFS using Filebase-managed pinning
- [ ] Build minimal CLI audit verifier: given `decision_id`, prove or disprove tamper-proof

### Phase 1 — Testnet Integration (3–4 weeks)
- [ ] Deploy contracts to Base Sepolia
- [ ] Integrate ZeroDev ERC-4337 wallet for agent execution
- [ ] Build Next.js dashboard: live decision feed + WYSIWYS calldata decoder
- [ ] Integrate Privy for user authentication
- [ ] Add `raiseChallenge` UI flow with Push Protocol notification
- [ ] Implement Linked-Record Hash Chain (prev_record_hash)
- [ ] Add OPA policy engine with configurable YAML rules
- [ ] Tenderly simulation API integration

### Phase 2 — Security & Governance (3–4 weeks)
- [ ] Implement Challenger Bond Staking in ChallengeRegistry.sol
- [ ] Build Verifier Agent rotation logic (block-hash-seeded pool selection)
- [ ] Implement Anomaly Score extended challenge window
- [ ] Add Kill Switch (Pausable module) to agent wallet
- [ ] Build public-facing Audit Explorer page
- [ ] Stress test: simulate 500 decisions/minute with batch anchoring
- [ ] Write test suite: tamper detection, challenge flow, Merkle proof

### Phase 3 — Multi-Agent & DAO Governance (4–5 weeks)
- [ ] Integrate OpenZeppelin Governor for DAO vote on challenges
- [ ] Add Verifier agent pool on-chain registry
- [ ] Implement agent reputation score updated by challenge outcomes
- [ ] Add multi-agent swarm support (multiple Proposers → shared Verifier pool)
- [ ] Full audit trail for swarm decisions (aggregate DRS → swarm DRS)

---

## 14. Verification Plan

### Automated Tests
```bash
# Smart contracts
forge test --fork-url $BASE_SEPOLIA_RPC -vvv
# Expected: AuditAnchor anchors correctly, Merkle verify passes, Challenge lifecycle works

# Agent integration
pytest tests/test_drs_builder.py -v
pytest tests/test_merkle_batcher.py -v
pytest tests/test_verifier_agent.py -v
pytest tests/test_ipfs_upload.py -v

# Policy engine
opa test policies/ -v

# E2E browser
npx playwright test e2e/challenge_flow.spec.ts
npx playwright test e2e/audit_explorer.spec.ts
```

### Security Attacks to Simulate
| Attack | Mitigation Being Tested |
|---|---|
| Operator edits a DRS after the fact | Merkle Root mismatch detected on-chain |
| Agent skips a decision in the chain | `prev_record_hash` chain break detected by Verifier |
| Proposer and Verifier collude | Verifier rotation prevents fixed pairs |
| Spam challenges to block execution | Bond staking makes spam economically costly |
| Agent submits wrong reasoning trace | Verifier re-derives reasoning from raw data, catches mismatch |
| Kill switch test | Agent wallet paused → all pending UserOps fail cleanly |
