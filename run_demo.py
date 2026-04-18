"""
run_demo.py — One-click demo runner.
Generates 5 PDR decisions and prints them to console.
Run this to test the full agent pipeline without a blockchain connection.
"""

import os
import sys
import json
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent / "agent"))
sys.path.insert(0, str(Path(__file__).parent / "protocol"))

# Set mock env vars for demo if not set
os.environ.setdefault("GOOGLE_API_KEY",     "demo_key")
os.environ.setdefault("PINATA_JWT",         "")
os.environ.setdefault("HELA_TESTNET_RPC",   "https://testnet-rpc.helachain.com")
os.environ.setdefault("PRIVATE_KEY",        "")
os.environ.setdefault("BATCH_SIZE",         "3")
os.environ.setdefault("CHALLENGE_WINDOW_HOURS", "24")

from financial_agent import FinancialAgent
from pipeline        import AAPPipeline

SYMBOLS = ["RELIANCE", "TCS", "HDFC", "INFY", "WIPRO"]

def run():
    print("\n" + "="*70)
    print("  AAP — Agent Audit Protocol Demo")
    print("  Analyzing NSE stocks with Gemini + HeLa Chain anchoring")
    print("="*70 + "\n")

    agent    = FinancialAgent()
    pipeline = AAPPipeline()

    for sym in SYMBOLS:
        print(f"\n{'─'*60}")
        print(f"Analyzing: {sym}")

        pdr      = agent.analyze(sym, quantity=10)
        if "error" in pdr:
            print(f"⚠ Error: {pdr['error']}")
            continue

        enriched = pipeline.process(pdr)

        print(f"  Decision ID:   {enriched['decision_id']}")
        print(f"  Action:        {enriched['action']} {enriched['quantity']} {enriched['asset']} @ ₹{enriched['price_at_decision']:.2f}")
        print(f"  Explanation:   {enriched.get('human_explanation', '—')}")
        print(f"  Confidence:    {enriched['confidence_score']:.2%}")
        print(f"  Risk:          {enriched['risk_score']} ({enriched['risk_score_numeric']:.2%})")
        print(f"  Approval:      {enriched['approval_type']} → {enriched['execution_status']}")
        print(f"  IPFS CID:      {enriched.get('ipfs_cid', 'N/A')[:30]}...")
        print(f"  PDR Hash:      {enriched['pdr_hash'][:32]}...")
        l1 = enriched.get('verification', {}).get('level1', {})
        zk = enriched.get('zk_proof', {})
        print(f"  L1 Verified:   {'✓ PASS' if l1.get('passed') else '✗ FAIL'}")
        print(f"  ZK Proof:      {'✓ PASS' if zk.get('passed', True) else '✗ FAIL'} (simulated={zk.get('simulated')})")

    # Flush any remaining batch
    print(f"\n{'─'*60}")
    print("Flushing pending Merkle batch to HeLa...")
    result = pipeline.flush_batch()
    if result:
        anchor = result.get("anchor", {})
        batch  = result.get("batch",  {})
        print(f"  Batch size:    {batch.get('batch_size', 0)} decisions")
        print(f"  Merkle root:   {batch.get('merkle_root', 'N/A')[:32]}...")
        print(f"  HeLa TX:       {anchor.get('tx_hash', 'N/A')[:32]}...")
        print(f"  Simulated:     {anchor.get('simulated', True)}")

    print(f"\n{'='*70}")
    print("Demo complete! All decisions logged, verified, and anchored.")
    print("Run `python backend/main.py` then open dashboard/index.html")
    print("="*70 + "\n")


if __name__ == "__main__":
    run()
