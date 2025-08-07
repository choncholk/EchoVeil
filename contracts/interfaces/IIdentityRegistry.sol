// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IIdentityRegistry
 * @notice Interface for identity binding and credential tracking
 * @dev Manages zero-knowledge identity registration and nullifier validation
 */
interface IIdentityRegistry {
    /**
     * @notice Emitted when a new identity is registered
     * @param user Address of the user registering identity
     * @param identityHash Hash of the user's identity commitment
     * @param timestamp Registration timestamp
     */
    event IdentityRegistered(
        address indexed user,
        bytes32 indexed identityHash,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a nullifier is consumed
     * @param nullifier The consumed nullifier hash
     * @param user Address that consumed the nullifier
     */
    event NullifierConsumed(bytes32 indexed nullifier, address indexed user);

    /**
     * @notice Register a new identity with zero-knowledge proof
     * @param identityHash Commitment hash of the user's identity
     * @param zkProof Zero-knowledge proof data
     */
    function registerIdentity(bytes32 identityHash, bytes calldata zkProof) external;

    /**
     * @notice Validate if a nullifier has been used
     * @param nullifier The nullifier hash to check
     * @return bool True if nullifier is valid (not used)
     */
    function validateNullifier(bytes32 nullifier) external view returns (bool);

    /**
     * @notice Mark a nullifier as consumed
     * @param nullifier The nullifier hash to consume
     */
    function consumeNullifier(bytes32 nullifier) external;

    /**
     * @notice Get identity hash for a user address
     * @param user The user address to query
     * @return bytes32 The identity hash
     */
    function getIdentityHash(address user) external view returns (bytes32);

    /**
     * @notice Check if an address has registered identity
     * @param user The user address to check
     * @return bool True if identity is registered
     */
    function isRegistered(address user) external view returns (bool);
}

# Interface polish
