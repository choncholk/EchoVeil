// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IIdentityRegistry.sol";

/**
 * @title IdentityRegistry
 * @notice Manages zero-knowledge identity registration and nullifier tracking
 * @dev Core contract for Sybil-resistant identity binding
 */
contract IdentityRegistry is IIdentityRegistry {
    /// @notice Mapping from user address to identity commitment hash
    mapping(address => bytes32) private identityHashes;

    /// @notice Mapping to track used nullifiers (prevents double-spending)
    mapping(bytes32 => bool) private usedNullifiers;

    /// @notice Mapping from user address to registration timestamp
    mapping(address => uint256) private registrationTimestamps;

    /// @notice Address of the ZK verifier contract
    address public immutable zkVerifier;

    /// @notice Minimum proof validity period
    uint256 public constant MIN_PROOF_AGE = 1 hours;

    /**
     * @notice Constructor
     * @param _zkVerifier Address of the ZK verifier contract
     */
    constructor(address _zkVerifier) {
        require(_zkVerifier != address(0), "Invalid verifier address");
        zkVerifier = _zkVerifier;
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function registerIdentity(
        bytes32 identityHash,
        bytes calldata zkProof
    ) external override {
        require(identityHash != bytes32(0), "Invalid identity hash");
        require(
            identityHashes[msg.sender] == bytes32(0),
            "Identity already registered"
        );

        // In production, verify ZK proof here
        // For now, accept any non-empty proof
        require(zkProof.length > 0, "Invalid proof");

        identityHashes[msg.sender] = identityHash;
        registrationTimestamps[msg.sender] = block.timestamp;

        emit IdentityRegistered(msg.sender, identityHash, block.timestamp);
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function validateNullifier(
        bytes32 nullifier
    ) external view override returns (bool) {
        return !usedNullifiers[nullifier];
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function consumeNullifier(bytes32 nullifier) external override {
        require(!usedNullifiers[nullifier], "Nullifier already used");
        require(
            identityHashes[msg.sender] != bytes32(0),
            "Identity not registered"
        );

        usedNullifiers[nullifier] = true;
        emit NullifierConsumed(nullifier, msg.sender);
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function getIdentityHash(
        address user
    ) external view override returns (bytes32) {
        return identityHashes[user];
    }

    /**
     * @inheritdoc IIdentityRegistry
     */
    function isRegistered(address user) external view override returns (bool) {
        return identityHashes[user] != bytes32(0);
    }

    /**
     * @notice Get registration timestamp for a user
     * @param user The user address to query
     * @return uint256 Registration timestamp
     */
    function getRegistrationTimestamp(
        address user
    ) external view returns (uint256) {
        return registrationTimestamps[user];
    }

    /**
     * @notice Check if a nullifier has been used
     * @param nullifier The nullifier to check
     * @return bool True if nullifier has been used
     */
    function isNullifierUsed(bytes32 nullifier) external view returns (bool) {
        return usedNullifiers[nullifier];
    }
}

// Identity registry optimization
