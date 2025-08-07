// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IZKVerifier
 * @notice Interface for zero-knowledge proof verification
 * @dev Implements Groth16 proof verification for reputation claims
 */
interface IZKVerifier {
    /**
     * @notice Emitted when a proof is verified
     * @param verifier Address that requested verification
     * @param success Whether verification succeeded
     * @param timestamp Verification timestamp
     */
    event ProofVerified(
        address indexed verifier,
        bool success,
        uint256 timestamp
    );

    /**
     * @dev Proof structure for Groth16
     */
    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    /**
     * @notice Verify a reputation proof
     * @param proof The zero-knowledge proof
     * @param publicSignals Public inputs to the circuit
     * @return bool True if proof is valid
     */
    function verifyReputationProof(
        Proof calldata proof,
        uint256[] calldata publicSignals
    ) external view returns (bool);

    /**
     * @notice Verify Merkle inclusion proof
     * @param proof The zero-knowledge proof
     * @param root Merkle root
     * @param nullifier Nullifier hash
     * @param commitment User commitment
     * @return bool True if proof is valid
     */
    function verifyMerkleInclusion(
        Proof calldata proof,
        bytes32 root,
        bytes32 nullifier,
        bytes32 commitment
    ) external view returns (bool);

    /**
     * @notice Verify eligibility proof (score threshold)
     * @param proof The zero-knowledge proof
     * @param root Merkle root
     * @param threshold Minimum reputation score
     * @param nullifier Nullifier hash
     * @return bool True if proof is valid
     */
    function verifyEligibilityProof(
        Proof calldata proof,
        bytes32 root,
        uint256 threshold,
        bytes32 nullifier
    ) external view returns (bool);

    /**
     * @notice Get verifying key hash for circuit version
     * @return bytes32 Hash of the verifying key
     */
    function getVerifyingKeyHash() external view returns (bytes32);
}

# ZKVerifier interface polish
