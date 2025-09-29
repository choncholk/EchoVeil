// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IReputationCore
 * @notice Interface for reputation Merkle root management
 * @dev Stores and manages epoch-based reputation tree roots
 */
interface IReputationCore {
    /**
     * @notice Emitted when Merkle root is updated
     * @param epoch The epoch number
     * @param newRoot The new Merkle root
     * @param previousRoot The previous Merkle root
     * @param timestamp Update timestamp
     */
    event RootUpdated(
        uint256 indexed epoch,
        bytes32 indexed newRoot,
        bytes32 previousRoot,
        uint256 timestamp
    );

    /**
     * @notice Emitted when epoch transitions
     * @param oldEpoch Previous epoch number
     * @param newEpoch New epoch number
     */
    event EpochTransitioned(uint256 oldEpoch, uint256 newEpoch);

    /**
     * @notice Update the Merkle root for current epoch
     * @param newRoot The new Merkle root hash
     * @dev Only callable by authorized oracle or guardian
     */
    function updateRoot(bytes32 newRoot) external;

    /**
     * @notice Get the current Merkle root
     * @return bytes32 Current Merkle root
     */
    function getCurrentRoot() external view returns (bytes32);

    /**
     * @notice Get the current epoch number
     * @return uint256 Current epoch
     */
    function getCurrentEpoch() external view returns (uint256);

    /**
     * @notice Get Merkle root for specific epoch
     * @param epoch The epoch number to query
     * @return bytes32 Merkle root for the epoch
     */
    function getRootAtEpoch(uint256 epoch) external view returns (bytes32);

    /**
     * @notice Check if a root is valid for current epoch
     * @param root The root hash to validate
     * @return bool True if root is valid
     */
    function isValidRoot(bytes32 root) external view returns (bool);

    /**
     * @notice Advance to next epoch
     * @dev Only callable by authorized accounts
     */
    function advanceEpoch() external;
}

