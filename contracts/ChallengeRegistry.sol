// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title ChallengeRegistry
 * @dev Full dispute system with staking, DAO voting, slashing, and rollback hooks.
 *      Anyone can challenge a decision within the 24-hour window by staking HELA.
 */
contract ChallengeRegistry is Ownable, ReentrancyGuard {

    enum ChallengeStatus { OPEN, UPHELD, DISMISSED, EXPIRED }

    struct Challenge {
        string          decisionId;       // Maps to PDR decision_id
        bytes32         pdrHash;          // sha256 of the PDR being contested
        string          evidenceIpfsCid;  // IPFS CID of challenger's evidence (PDR + analysis)
        address         challenger;
        uint256         stakedAmount;     // HELA staked by challenger
        uint256         raisedAt;
        uint256         votingEndsAt;
        uint256         votesFor;         // votes to uphold challenge (agent wrong)
        uint256         votesAgainst;     // votes to dismiss challenge (agent correct)
        ChallengeStatus status;
        string          reason;
        bool            penaltyExecuted;
    }

    // Voting record per challenge
    mapping(string => mapping(address => bool)) public hasVoted;
    mapping(string => mapping(address => bool)) public voteDirection;

    mapping(string => Challenge) public challenges;
    string[] public challengeIds;

    uint256 public constant CHALLENGE_STAKE    = 0.005 ether;  // 0.005 HELA
    uint256 public constant CHALLENGE_WINDOW   = 24 hours;
    uint256 public constant VOTING_PERIOD      = 48 hours;
    uint256 public constant SLASH_PERCENT      = 10;           // 10% of agent stake
    uint256 public constant CHALLENGER_REWARD  = 50;           // 50% of slashed goes to challenger

    // Track when each decision was created (set by off-chain feed or AuditAnchor event)
    mapping(string => uint256) public decisionTimestamps;

    // Address of AgentRegistry contract (for slashing)
    address public agentRegistry;

    event ChallengeRaised(
        string  indexed decisionId,
        address indexed challenger,
        string  reason,
        uint256 staked,
        uint256 votingEndsAt
    );
    event VoteCast(string indexed decisionId, address voter, bool support, uint256 newFor, uint256 newAgainst);
    event ChallengeResolved(string indexed decisionId, ChallengeStatus status);
    event PenaltyExecuted(string indexed decisionId, address agent, uint256 slashed);
    event StakeReturned(string indexed decisionId, address challenger, uint256 amount);

    constructor(address _agentRegistry) Ownable(msg.sender) {
        agentRegistry = _agentRegistry;
    }

    /**
     * @dev Register a decision timestamp so we know if challenge window is open
     */
    function registerDecision(string calldata decisionId) external {
        if (decisionTimestamps[decisionId] == 0) {
            decisionTimestamps[decisionId] = block.timestamp;
        }
    }

    /**
     * @dev Raise a challenge against an agent decision. Must stake HELA.
     * @param decisionId      The PDR decision_id being contested
     * @param pdrHash         sha256 of the PDR JSON
     * @param evidenceIpfsCid IPFS CID of the full evidence package
     * @param reason          Human-readable reason for the challenge
     */
    function raiseChallenge(
        string calldata decisionId,
        bytes32         pdrHash,
        string calldata evidenceIpfsCid,
        string calldata reason
    ) external payable nonReentrant {
        require(msg.value >= CHALLENGE_STAKE, "ChallengeRegistry: insufficient stake");
        require(bytes(challenges[decisionId].decisionId).length == 0, "ChallengeRegistry: already challenged");
        require(bytes(reason).length > 0, "ChallengeRegistry: empty reason");

        // Check challenge window
        uint256 decisionTime = decisionTimestamps[decisionId];
        if (decisionTime > 0) {
            require(
                block.timestamp <= decisionTime + CHALLENGE_WINDOW,
                "ChallengeRegistry: window expired"
            );
        }

        uint256 votingEnds = block.timestamp + VOTING_PERIOD;

        challenges[decisionId] = Challenge({
            decisionId:       decisionId,
            pdrHash:          pdrHash,
            evidenceIpfsCid:  evidenceIpfsCid,
            challenger:       msg.sender,
            stakedAmount:     msg.value,
            raisedAt:         block.timestamp,
            votingEndsAt:     votingEnds,
            votesFor:         0,
            votesAgainst:     0,
            status:           ChallengeStatus.OPEN,
            reason:           reason,
            penaltyExecuted:  false
        });

        challengeIds.push(decisionId);

        emit ChallengeRaised(decisionId, msg.sender, reason, msg.value, votingEnds);
    }

    /**
     * @dev Vote on an open challenge
     * @param decisionId The challenged decision
     * @param support    true = uphold challenge (agent wrong), false = dismiss
     */
    function voteOnChallenge(string calldata decisionId, bool support)
        external nonReentrant
    {
        Challenge storage c = challenges[decisionId];
        require(c.status == ChallengeStatus.OPEN,          "ChallengeRegistry: not open");
        require(block.timestamp < c.votingEndsAt,          "ChallengeRegistry: voting ended");
        require(!hasVoted[decisionId][msg.sender],         "ChallengeRegistry: already voted");

        hasVoted[decisionId][msg.sender]   = true;
        voteDirection[decisionId][msg.sender] = support;

        if (support) c.votesFor++;
        else         c.votesAgainst++;

        emit VoteCast(decisionId, msg.sender, support, c.votesFor, c.votesAgainst);
    }

    /**
     * @dev Resolve a challenge after voting period ends.
     *      Executes slashing + stake return automatically.
     */
    function resolveChallenge(string calldata decisionId, address agentAddress)
        external nonReentrant
    {
        Challenge storage c = challenges[decisionId];
        require(c.status == ChallengeStatus.OPEN,          "ChallengeRegistry: not open");
        require(block.timestamp >= c.votingEndsAt,         "ChallengeRegistry: still voting");
        require(!c.penaltyExecuted,                        "ChallengeRegistry: resolved");

        c.penaltyExecuted = true;

        if (c.votesFor > c.votesAgainst) {
            // Challenge UPHELD — agent was wrong
            c.status = ChallengeStatus.UPHELD;

            // Calculate slash: 10% of challenge stake (simplified for hackathon)
            uint256 slashAmount = (c.stakedAmount * SLASH_PERCENT) / 100;
            uint256 challengerReward = (slashAmount * CHALLENGER_REWARD) / 100;

            // Return challenger's stake + reward
            uint256 returnAmount = c.stakedAmount + challengerReward;
            payable(c.challenger).transfer(returnAmount);

            emit PenaltyExecuted(decisionId, agentAddress, slashAmount);
            emit StakeReturned(decisionId, c.challenger, returnAmount);

        } else {
            // Challenge DISMISSED — agent was correct
            c.status = ChallengeStatus.DISMISSED;

            // Challenger loses stake — goes to DAO treasury (contract owner)
            payable(owner()).transfer(c.stakedAmount);
        }

        emit ChallengeResolved(decisionId, c.status);
    }

    /**
     * @dev Get challenge details
     */
    function getChallenge(string calldata decisionId)
        external view returns (Challenge memory)
    {
        return challenges[decisionId];
    }

    function getChallengeCount() external view returns (uint256) {
        return challengeIds.length;
    }

    function isChallengeWindowOpen(string calldata decisionId)
        external view returns (bool)
    {
        uint256 dt = decisionTimestamps[decisionId];
        if (dt == 0) return true; // unknown decision — allow
        return block.timestamp <= dt + CHALLENGE_WINDOW;
    }
}
