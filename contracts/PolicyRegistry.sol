// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PolicyRegistry
 * @dev Stores DAO-managed trading rules. 
 *      Hardcoded rules cannot be changed (immutable safety floor).
 *      Community rules are proposed and voted on by HELA token holders.
 */
contract PolicyRegistry is Ownable {

    // ── Hardcoded rules (written in contract, unchangeable) ───────────────
    uint256 public constant MAX_PORTFOLIO_PCT_PER_TRADE = 5;    // 5% max
    uint256 public constant MARKET_OPEN_BUFFER_MINUTES  = 15;   // no trades first 15min
    uint256 public constant MINIMUM_AGENT_STAKE_HELA    = 0.01 ether;
    uint256 public constant MAX_SLASHES_BEFORE_BAN      = 3;

    // ── Community rules (changeable via DAO vote) ─────────────────────────
    struct CommunityRule {
        uint256 ruleId;
        string  key;           // e.g. "AUTO_APPROVE_LIMIT_INR"
        string  value;         // e.g. "10000"
        string  description;
        bool    active;
        uint256 createdAt;
        uint256 votesFor;
        uint256 votesAgainst;
        bool    enacted;
    }

    mapping(uint256 => CommunityRule) public rules;
    uint256 public ruleCount;

    // Active community rule values (key => value)
    mapping(string => string) public activeValues;

    // DAO members who have voted on each rule
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Voting parameters
    uint256 public constant VOTING_PERIOD  = 72 hours;
    uint256 public constant QUORUM_PERCENT = 60; // 60% required to pass

    mapping(uint256 => uint256) public ruleProposedAt;

    event RuleProposed(uint256 indexed ruleId, string key, string value, address proposer);
    event VoteCast(uint256 indexed ruleId, address voter, bool support);
    event RuleEnacted(uint256 indexed ruleId, string key, string value);

    constructor() Ownable(msg.sender) {
        // Seed default community rules
        _seedRule("AUTO_APPROVE_LIMIT_INR", "10000",   "Auto-approve trades below this INR value");
        _seedRule("RISK_SCORE_AUTO_THRESHOLD", "0.5",  "Risk score above this requires manual approval");
        _seedRule("ALLOWED_ASSETS",  "RELIANCE,TCS,HDFC,INFY,WIPRO,BHARTIARTL,ICICIBANK,KOTAKBANK", "Tradeable NSE symbols");
        _seedRule("CHALLENGE_STAKE_HELA", "0.005",     "HELA required to raise a challenge");
        _seedRule("CHALLENGE_WINDOW_HOURS", "24",      "Hours within which a decision can be challenged");
        _seedRule("MAX_TRADES_PER_HOUR", "10",         "Rate limit for agent decisions");
    }

    function _seedRule(string memory key, string memory val, string memory desc) internal {
        uint256 id = ruleCount++;
        rules[id] = CommunityRule({
            ruleId:      id,
            key:         key,
            value:       val,
            description: desc,
            active:      true,
            createdAt:   block.timestamp,
            votesFor:    0,
            votesAgainst:0,
            enacted:     true
        });
        activeValues[key] = val;
        ruleProposedAt[id] = block.timestamp;
    }

    /**
     * @dev Propose a new community rule (any DAO member)
     */
    function proposeRule(
        string calldata key,
        string calldata value,
        string calldata description
    ) external returns (uint256) {
        uint256 id = ruleCount++;
        rules[id] = CommunityRule({
            ruleId:      id,
            key:         key,
            value:       value,
            description: description,
            active:      true,
            createdAt:   block.timestamp,
            votesFor:    0,
            votesAgainst:0,
            enacted:     false
        });
        ruleProposedAt[id] = block.timestamp;
        emit RuleProposed(id, key, value, msg.sender);
        return id;
    }

    /**
     * @dev Vote on a pending rule
     */
    function voteOnRule(uint256 ruleId, bool support) external {
        require(!rules[ruleId].enacted, "PolicyRegistry: already enacted");
        require(!hasVoted[ruleId][msg.sender], "PolicyRegistry: already voted");
        require(
            block.timestamp <= ruleProposedAt[ruleId] + VOTING_PERIOD,
            "PolicyRegistry: voting ended"
        );

        hasVoted[ruleId][msg.sender] = true;
        if (support) rules[ruleId].votesFor++;
        else         rules[ruleId].votesAgainst++;

        emit VoteCast(ruleId, msg.sender, support);
    }

    /**
     * @dev Enact a rule after voting period + quorum met
     */
    function enactRule(uint256 ruleId) external {
        CommunityRule storage r = rules[ruleId];
        require(!r.enacted, "PolicyRegistry: already enacted");
        require(
            block.timestamp > ruleProposedAt[ruleId] + VOTING_PERIOD,
            "PolicyRegistry: voting not ended"
        );
        uint256 total = r.votesFor + r.votesAgainst;
        require(total > 0, "PolicyRegistry: no votes");
        require(
            r.votesFor * 100 / total >= QUORUM_PERCENT,
            "PolicyRegistry: quorum not met"
        );

        r.enacted = true;
        activeValues[r.key] = r.value;
        emit RuleEnacted(ruleId, r.key, r.value);
    }

    /**
     * @dev Get current active value for a rule key
     */
    function getActiveValue(string calldata key) external view returns (string memory) {
        return activeValues[key];
    }

    /**
     * @dev Get all active rules as parallel arrays (for off-chain consumption)
     */
    function getAllActiveRules()
        external view
        returns (string[] memory keys, string[] memory values)
    {
        uint256 count = ruleCount;
        keys   = new string[](count);
        values = new string[](count);
        for (uint256 i = 0; i < count; i++) {
            if (rules[i].enacted) {
                keys[i]   = rules[i].key;
                values[i] = rules[i].value;
            }
        }
    }
}
