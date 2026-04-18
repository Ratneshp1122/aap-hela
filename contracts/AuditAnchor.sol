// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title AuditAnchor
 * @dev Stores Merkle roots of batched PDR hashes on HeLa Chain.
 *      Each root represents up to 100 agent decisions at negligible gas cost.
 */
contract AuditAnchor is Ownable, Pausable {

    struct AnchorRecord {
        bytes32 merkleRoot;
        uint256 timestamp;
        address agentAddress;
        uint256 batchSize;
        string  ipfsIndexCid;
        uint256 blockNumber;
    }

    // agentAddress => list of anchor records
    mapping(address => AnchorRecord[]) public anchors;

    // Global counter
    uint256 public totalAnchors;
    uint256 public totalDecisionsAnchored;

    event RootAnchored(
        bytes32 indexed merkleRoot,
        address indexed agent,
        uint256 timestamp,
        uint256 batchSize,
        string  ipfsIndexCid,
        uint256 anchorIndex
    );

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Anchor a Merkle root representing a batch of PDR hashes.
     * @param merkleRoot  Root of the Merkle tree built from sha256(PDR JSON) leaves
     * @param batchSize   Number of decisions in this batch
     * @param ipfsIndexCid IPFS CID pointing to the full batch index JSON
     */
    function anchorRoot(
        bytes32 merkleRoot,
        uint256 batchSize,
        string calldata ipfsIndexCid
    ) external whenNotPaused {
        require(batchSize > 0, "AuditAnchor: empty batch");
        require(bytes(ipfsIndexCid).length > 0, "AuditAnchor: no IPFS CID");

        uint256 anchorIndex = anchors[msg.sender].length;

        anchors[msg.sender].push(AnchorRecord({
            merkleRoot:   merkleRoot,
            timestamp:    block.timestamp,
            agentAddress: msg.sender,
            batchSize:    batchSize,
            ipfsIndexCid: ipfsIndexCid,
            blockNumber:  block.number
        }));

        totalAnchors++;
        totalDecisionsAnchored += batchSize;

        emit RootAnchored(
            merkleRoot,
            msg.sender,
            block.timestamp,
            batchSize,
            ipfsIndexCid,
            anchorIndex
        );
    }

    /**
     * @dev Verify a single decision hash (leaf) belongs to an anchored batch.
     * @param agent        The agent address that anchored
     * @param anchorIndex  Index into that agent's anchor array
     * @param leaf         sha256 hash of the PDR JSON (32 bytes)
     * @param proof        Merkle proof path
     */
    function verifyLeaf(
        address agent,
        uint256 anchorIndex,
        bytes32 leaf,
        bytes32[] calldata proof
    ) external view returns (bool) {
        require(anchorIndex < anchors[agent].length, "AuditAnchor: invalid index");
        bytes32 root = anchors[agent][anchorIndex].merkleRoot;
        return MerkleProof.verify(proof, root, leaf);
    }

    /**
     * @dev Get anchor count for an agent
     */
    function getAnchorCount(address agent) external view returns (uint256) {
        return anchors[agent].length;
    }

    /**
     * @dev Get a specific anchor record
     */
    function getAnchor(address agent, uint256 index)
        external view returns (AnchorRecord memory)
    {
        require(index < anchors[agent].length, "AuditAnchor: out of bounds");
        return anchors[agent][index];
    }

    // Emergency pause — only owner (multisig in production)
    function pause()   external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }
}
