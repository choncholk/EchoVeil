// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IProofGateway.sol";
import "../interfaces/IZKVerifier.sol";

/**
 * @title AirdropExample
 * @notice Example dApp using EchoVeil for reputation-based airdrop
 * @dev Demonstrates how to integrate EchoVeil proof verification
 */
contract AirdropExample {
    /// @notice Proof Gateway contract
    IProofGateway public immutable proofGateway;

    /// @notice Airdrop token amount per claim
    uint256 public constant AIRDROP_AMOUNT = 1000 ether;

    /// @notice Minimum reputation score required
    uint256 public constant MIN_REPUTATION = 100;

    /// @notice Mapping of claimed airdrops
    mapping(bytes32 => bool) public claimed;

    /// @notice Total tokens distributed
    uint256 public totalDistributed;

    /// @notice Total number of claims
    uint256 public totalClaims;

    /**
     * @notice Emitted when airdrop is claimed
     */
    event AirdropClaimed(
        address indexed user,
        bytes32 indexed nullifier,
        uint256 amount,
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
     * @notice Claim airdrop with ZK proof
     * @param proof Zero-knowledge proof
     * @param merkleRoot Current reputation Merkle root
     * @param epoch Current epoch
     * @param nullifier User nullifier (prevents double claiming)
     */
    function claimAirdrop(
        IZKVerifier.Proof calldata proof,
        bytes32 merkleRoot,
        uint256 epoch,
        bytes32 nullifier
    ) external {
        require(!claimed[nullifier], "Already claimed");

        // Create eligibility requirement
        IProofGateway.EligibilityRequirement memory requirement = 
            IProofGateway.EligibilityRequirement({
                merkleRoot: merkleRoot,
                minScore: MIN_REPUTATION,
                maxScore: type(uint256).max,
                epoch: epoch,
                requireSybilResistance: true
            });

        // Verify proof through gateway
        IProofGateway.VerificationResult memory result = 
            proofGateway.verifyEligibility(proof, requirement, nullifier);

        require(result.success, "Proof verification failed");

        // Mark as claimed
        claimed[nullifier] = true;
        totalClaims++;
        totalDistributed += AIRDROP_AMOUNT;

        // Transfer tokens (in production, would transfer actual tokens)
        // For this example, we just emit an event
        emit AirdropClaimed(msg.sender, nullifier, AIRDROP_AMOUNT, block.timestamp);
    }

    /**
     * @notice Check if nullifier has claimed
     * @param nullifier Nullifier to check
     * @return bool True if claimed
     */
    function hasClaimed(bytes32 nullifier) external view returns (bool) {
        return claimed[nullifier];
    }

    /**
     * @notice Get airdrop statistics
     * @return claims Total number of claims
     * @return distributed Total amount distributed
     */
    function getStats() external view returns (uint256 claims, uint256 distributed) {
        return (totalClaims, totalDistributed);
    }
}

