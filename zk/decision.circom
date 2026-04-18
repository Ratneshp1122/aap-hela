pragma circom 2.0.0;

/*
 * ConstrainedDecision.circom
 * 
 * Proves a financial agent decision followed all rules
 * WITHOUT revealing the exact values of private inputs.
 *
 * Public inputs:  action_hash, min_confidence, max_risk, rsi_min, rsi_max
 * Private inputs: rsi (scaled x100), confidence (scaled x1000), risk_score (scaled x1000)
 *
 * Constraints proved:
 *   1. confidence >= min_confidence (0.40 * 1000 = 400)
 *   2. risk_score <= max_risk       (0.80 * 1000 = 800)
 *   3. rsi >= rsi_min               (20.0 * 100  = 2000)
 *   4. rsi <= rsi_max               (80.0 * 100  = 8000)
 */

include "node_modules/circomlib/circuits/comparators.circom";

template ConstrainedDecision() {
    // ── Private Inputs (not revealed) ──────────────────────
    signal input rsi;           // RSI * 100 (e.g., 42.3 → 4230)
    signal input confidence;    // Confidence * 1000 (e.g., 0.87 → 870)
    signal input risk_score;    // Risk score * 1000 (e.g., 0.42 → 420)

    // ── Public Inputs (verifier can see) ───────────────────
    signal input action_hash;   // hash(action) truncated to uint
    signal input min_confidence;// Minimum confidence (e.g., 400 = 0.40)
    signal input max_risk;      // Maximum risk score (e.g., 800 = 0.80)
    signal input rsi_min;       // RSI lower bound (e.g., 2000 = 20.0)
    signal input rsi_max;       // RSI upper bound (e.g., 8000 = 80.0)

    // ── Output ─────────────────────────────────────────────
    signal output valid;        // 1 if all constraints satisfied, 0 otherwise

    // ── Constraints ────────────────────────────────────────

    // 1. confidence >= min_confidence
    component conf_check = GreaterEqThan(32);
    conf_check.in[0] <== confidence;
    conf_check.in[1] <== min_confidence;

    // 2. risk_score <= max_risk (i.e., max_risk >= risk_score)
    component risk_check = GreaterEqThan(32);
    risk_check.in[0] <== max_risk;
    risk_check.in[1] <== risk_score;

    // 3. rsi >= rsi_min
    component rsi_low_check = GreaterEqThan(32);
    rsi_low_check.in[0] <== rsi;
    rsi_low_check.in[1] <== rsi_min;

    // 4. rsi <= rsi_max (i.e., rsi_max >= rsi)
    component rsi_high_check = GreaterEqThan(32);
    rsi_high_check.in[0] <== rsi_max;
    rsi_high_check.in[1] <== rsi;

    // All constraints must pass (AND)
    signal temp1;
    signal temp2;
    signal temp3;

    temp1 <== conf_check.out * risk_check.out;
    temp2 <== rsi_low_check.out * rsi_high_check.out;
    temp3 <== temp1 * temp2;

    valid <== temp3;

    // Enforce valid == 1 (circuit fails if any constraint violated)
    valid === 1;
}

component main {public [action_hash, min_confidence, max_risk, rsi_min, rsi_max]} = ConstrainedDecision();
