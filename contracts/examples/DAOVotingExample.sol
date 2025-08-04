// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IProofGateway.sol";
import "../interfaces/IZKVerifier.sol";

/**
 * @title DAOVotingExample
 * @notice Example DAO voting with anonymous reputation-weighted votes
 * @dev Uses EchoVeil for Sybil-resistant anonymous voting
 */
contract DAOVotingExample {
    /// @notice Proof Gateway contract
    IProofGateway public immutable proofGateway;

    /// @notice Proposal structure
    struct Proposal {
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalVoters;
        bool executed;
        bytes32 merkleRoot;
        uint256 epoch;
    }

    /// @notice Array of all proposals
    Proposal[] public proposals;

    /// @notice Mapping from proposal ID to nullifiers (prevents double voting)
    mapping(uint256 => mapping(bytes32 => bool)) public hasVoted;

    /// @notice Minimum reputation to create proposal
    uint256 public constant CREATE_PROPOSAL_MIN_REP = 500;

    /// @notice Minimum reputation to vote
    uint256 public constant VOTE_MIN_REP = 100;

    /// @notice Voting period duration
    uint256 public constant VOTING_PERIOD = 7 days;

    /**
     * @notice Emitted when proposal is created
     */
    event ProposalCreated(
        uint256 indexed proposalId,
        string description,
        uint256 startTime,
        uint256 endTime
    );

    /**
     * @notice Emitted when vote is cast
     */
    event VoteCast(
        uint256 indexed proposalId,
        bytes32 indexed nullifier,
        bool support,
        uint256 timestamp
    );

    /**
     * @notice Emitted when proposal is executed
     */
    event ProposalExecuted(
        uint256 indexed proposalId,
        bool passed,
        uint256 timestamp
    );

    /**
     * @notice Constructor
     * @param _proofGateway Address of ProofGateway contract
     */
    constructor(address _proofGateway) {
        require(_proofGateway != address(0), "Invalid gateway address");
        proofGateway = IProofGateway(_proofGateway);
    }

    /**
     * @notice Create a new proposal (requires high reputation)
     * @param description Proposal description
     * @param proof ZK proof of high reputation
     * @param merkleRoot Current reputation root
     * @param epoch Current epoch
     * @param nullifier Creator nullifier
     */
    function createProposal(
        string calldata description,
        IZKVerifier.Proof calldata proof,
        bytes32 merkleRoot,
        uint256 epoch,
        bytes32 nullifier
    ) external returns (uint256 proposalId) {
        require(bytes(description).length > 0, "Empty description");

        // Verify creator has sufficient reputation
        IProofGateway.EligibilityRequirement memory requirement = 
            IProofGateway.EligibilityRequirement({
                merkleRoot: merkleRoot,
                minScore: CREATE_PROPOSAL_MIN_REP,
                maxScore: type(uint256).max,
                epoch: epoch,
                requireSybilResistance: true
            });

        IProofGateway.VerificationResult memory result = 
            proofGateway.verifyEligibility(proof, requirement, nullifier);

        require(result.success, "Insufficient reputation");

        // Create proposal
        proposalId = proposals.length;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + VOTING_PERIOD;

        proposals.push(Proposal({
            description: description,
            startTime: startTime,
            endTime: endTime,
            yesVotes: 0,
            noVotes: 0,
            totalVoters: 0,
            executed: false,
            merkleRoot: merkleRoot,
            epoch: epoch
        }));

        emit ProposalCreated(proposalId, description, startTime, endTime);
    }

    /**
     * @notice Cast vote on a proposal
     * @param proposalId ID of the proposal
     * @param support True for yes, false for no
     * @param proof ZK proof of reputation
     * @param nullifier Voter nullifier
     */
    function castVote(
        uint256 proposalId,
        bool support,
        IZKVerifier.Proof calldata proof,
        bytes32 nullifier
    ) external {
        require(proposalId < proposals.length, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!hasVoted[proposalId][nullifier], "Already voted");

        // Verify voter eligibility
        IProofGateway.EligibilityRequirement memory requirement = 
            IProofGateway.EligibilityRequirement({
                merkleRoot: proposal.merkleRoot,
                minScore: VOTE_MIN_REP,
                maxScore: type(uint256).max,
                epoch: proposal.epoch,
                requireSybilResistance: true
            });

        IProofGateway.VerificationResult memory result = 
            proofGateway.verifyEligibility(proof, requirement, nullifier);

        require(result.success, "Verification failed");

        // Record vote
        hasVoted[proposalId][nullifier] = true;
        proposal.totalVoters++;

        if (support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit VoteCast(proposalId, nullifier, support, block.timestamp);
    }

    /**
     * @notice Execute proposal after voting period
     * @param proposalId ID of the proposal
     */
    function executeProposal(uint256 proposalId) external {
        require(proposalId < proposals.length, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp > proposal.endTime, "Voting not ended");
        require(!proposal.executed, "Already executed");

        proposal.executed = true;
        bool passed = proposal.yesVotes > proposal.noVotes;

        emit ProposalExecuted(proposalId, passed, block.timestamp);
    }

    /**
     * @notice Get proposal details
     * @param proposalId ID of the proposal
     */
    function getProposal(uint256 proposalId) 
        external 
        view 
        returns (
            string memory description,
            uint256 startTime,
            uint256 endTime,
            uint256 yesVotes,
            uint256 noVotes,
            uint256 totalVoters,
            bool executed
        ) 
    {
        require(proposalId < proposals.length, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];

        return (
            proposal.description,
            proposal.startTime,
            proposal.endTime,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.totalVoters,
            proposal.executed
        );
    }

    /**
     * @notice Get proposal count
     */
    function getProposalCount() external view returns (uint256) {
        return proposals.length;
    }

    /**
     * @notice Check if proposal is active
     */
    function isProposalActive(uint256 proposalId) external view returns (bool) {
        require(proposalId < proposals.length, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];

        return block.timestamp >= proposal.startTime && 
               block.timestamp <= proposal.endTime &&
               !proposal.executed;
    }
}

// DAO example enhancements
