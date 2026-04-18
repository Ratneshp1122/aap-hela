// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AgentRegistry
 * @dev Registers autonomous agents with DID identity and HELA staking.
 *      Agents must stake HELA before being allowed to submit audit logs.
 */
contract AgentRegistry is Ownable {

    enum AgentStatus { UNREGISTERED, ACTIVE, SUSPENDED, DEACTIVATED }

    struct Agent {
        string  did;           // W3C DID: "did:hela:0x..."
        string  name;
        string  agentType;     // "FINANCIAL_TRADING", "GOVERNANCE", etc.
        address agentAddress;
        uint256 stakedAmount;  // HELA staked as bond
        uint256 registeredAt;
        uint256 slashCount;
        AgentStatus status;
    }

    uint256 public constant MINIMUM_STAKE = 0.01 ether; // 0.01 HELA for testnet
    uint256 public constant MAX_SLASHES   = 3;

    mapping(address => Agent) public agents;
    address[] public agentList;

    event AgentRegistered(address indexed agent, string did, string name, uint256 staked);
    event AgentSlashed(address indexed agent, uint256 amount, string reason);
    event AgentDeactivated(address indexed agent);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Register a new agent with staked HELA
     */
    function registerAgent(
        string calldata did,
        string calldata name,
        string calldata agentType
    ) external payable {
        require(msg.value >= MINIMUM_STAKE,    "AgentRegistry: insufficient stake");
        require(agents[msg.sender].agentAddress == address(0), "AgentRegistry: already registered");
        require(bytes(did).length > 0,  "AgentRegistry: empty DID");
        require(bytes(name).length > 0, "AgentRegistry: empty name");

        agents[msg.sender] = Agent({
            did:          did,
            name:         name,
            agentType:    agentType,
            agentAddress: msg.sender,
            stakedAmount: msg.value,
            registeredAt: block.timestamp,
            slashCount:   0,
            status:       AgentStatus.ACTIVE
        });

        agentList.push(msg.sender);
        emit AgentRegistered(msg.sender, did, name, msg.value);
    }

    /**
     * @dev Slash an agent's stake (called by ChallengeRegistry when challenge upheld)
     */
    function slashAgent(address agentAddr, uint256 amount, string calldata reason)
        external onlyOwner
    {
        Agent storage a = agents[agentAddr];
        require(a.status == AgentStatus.ACTIVE, "AgentRegistry: not active");

        uint256 slash = amount > a.stakedAmount ? a.stakedAmount : amount;
        a.stakedAmount -= slash;
        a.slashCount++;

        if (a.slashCount >= MAX_SLASHES) {
            a.status = AgentStatus.DEACTIVATED;
            emit AgentDeactivated(agentAddr);
        }

        // Transfer slashed amount to contract owner (DAO treasury)
        payable(owner()).transfer(slash);
        emit AgentSlashed(agentAddr, slash, reason);
    }

    /**
     * @dev Check if an agent is active and has sufficient stake
     */
    function isActive(address agentAddr) external view returns (bool) {
        return agents[agentAddr].status == AgentStatus.ACTIVE
            && agents[agentAddr].stakedAmount >= MINIMUM_STAKE;
    }

    function getAgent(address agentAddr) external view returns (Agent memory) {
        return agents[agentAddr];
    }

    function getAgentCount() external view returns (uint256) {
        return agentList.length;
    }
}
