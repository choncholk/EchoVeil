// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IZKVerifier.sol";

/**
 * @title IProofGateway
 * @notice Unified verification interface for dApps
 * @dev Gateway for all proof verification requests
 */
interface IProofGateway {
    /**
     * @dev Eligibility requirement structure
     */
    struct EligibilityRequirement {
        bytes32 merkleRoot;
        uint256 minScore;
        uint256 maxScore;
        uint256 epoch;
        bool requireSybilResistance;
    }

    /**
     * @dev Verification result structure
     */
    struct VerificationResult {
        bool success;
        bytes32 nullifier;
        uint256 timestamp;
        address verifier;
    }

    /**
     * @notice Emitted when eligibility is verified
     * @param user Address requesting verification
     * @param success Whether verification succeeded
     * @param nullifier Nullifier used in proof
     * @param timestamp Verification timestamp
     */
    event EligibilityVerified(
        address indexed user,
        bool success,
        bytes32 indexed nullifier,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a dApp registers for verification service
     * @param dapp Address of the dApp
     * @param timestamp Registration timestamp
     */
    event DAppRegistered(address indexed dapp, uint256 timestamp);

    /**
     * @notice Verify eligibility with ZK proof
     * @param proof The zero-knowledge proof
     * @param requirement Eligibility requirements
     * @param nullifier User nullifier
     * @return VerificationResult Result of verification
     */
    function verifyEligibility(
        IZKVerifier.Proof calldata proof,
        EligibilityRequirement calldata requirement,
        bytes32 nullifier
    ) external returns (VerificationResult memory);

    /**
     * @notice Batch verify multiple proofs
     * @param proofs Array of zero-knowledge proofs
     * @param requirements Array of eligibility requirements
     * @param nullifiers Array of nullifiers
     * @return results Array of verification results
     */
    function batchVerifyEligibility(
        IZKVerifier.Proof[] calldata proofs,
        EligibilityRequirement[] calldata requirements,
        bytes32[] calldata nullifiers
    ) external returns (VerificationResult[] memory results);

    /**
     * @notice Check if nullifier was used
     * @param nullifier The nullifier to check
     * @return bool True if nullifier was used
     */
    function isNullifierUsed(bytes32 nullifier) external view returns (bool);

    /**
     * @notice Register a dApp for verification service
     * @param metadata IPFS hash or metadata URI
     */
    function registerDApp(string calldata metadata) external;

    /**
     * @notice Get verification result for user
     * @param user User address
     * @param nullifier Nullifier hash
     * @return VerificationResult Verification result
     */
    function getVerificationResult(
        address user,
        bytes32 nullifier
    ) external view returns (VerificationResult memory);
}

