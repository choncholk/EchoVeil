// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IReputationCore.sol";

/**
 * @title ReputationCore
 * @notice Manages Merkle root storage and epoch transitions
 * @dev Core contract for reputation tree state management
 */
contract ReputationCore is IReputationCore {
    /// @notice Current Merkle root
    bytes32 private currentRoot;

    /// @notice Current epoch number
    uint256 private currentEpoch;

    /// @notice Mapping from epoch to Merkle root
    mapping(uint256 => bytes32) private epochRoots;

    /// @notice Mapping from root to validity status
    mapping(bytes32 => bool) private validRoots;

    /// @notice Guardian address (can update roots and manage epochs)
    address public guardian;

    /// @notice Oracle address (can update roots)
    address public oracle;

    /// @notice Minimum time between epoch transitions (1 day)
    uint256 public constant EPOCH_DURATION = 1 days;

    /// @notice Last epoch transition timestamp
    uint256 public lastEpochTransition;

    /// @notice Maximum historical epochs to keep
    uint256 public constant MAX_HISTORICAL_EPOCHS = 100;

    /**
     * @notice Only guardian can call
     */
    modifier onlyGuardian() {
        require(msg.sender == guardian, "Only guardian");
        _;
    }

    /**
     * @notice Only oracle or guardian can call
     */
    modifier onlyOracleOrGuardian() {
        require(
            msg.sender == oracle || msg.sender == guardian,
            "Only oracle or guardian"
        );
        _;
    }

    /**
     * @notice Constructor
     * @param _guardian Address of the guardian
     * @param _oracle Address of the oracle
     * @param _initialRoot Initial Merkle root
     */
    constructor(address _guardian, address _oracle, bytes32 _initialRoot) {
        require(_guardian != address(0), "Invalid guardian address");
        require(_oracle != address(0), "Invalid oracle address");

        guardian = _guardian;
        oracle = _oracle;
        currentRoot = _initialRoot;
        currentEpoch = 0;
        lastEpochTransition = block.timestamp;

        epochRoots[0] = _initialRoot;
        validRoots[_initialRoot] = true;

        emit RootUpdated(0, _initialRoot, bytes32(0), block.timestamp);
    }

    /**
     * @inheritdoc IReputationCore
     */
    function updateRoot(bytes32 newRoot) external override onlyOracleOrGuardian {
        require(newRoot != bytes32(0), "Invalid root");
        require(newRoot != currentRoot, "Root unchanged");

        bytes32 previousRoot = currentRoot;
        currentRoot = newRoot;
        epochRoots[currentEpoch] = newRoot;
        validRoots[newRoot] = true;

        emit RootUpdated(currentEpoch, newRoot, previousRoot, block.timestamp);
    }

    /**
     * @inheritdoc IReputationCore
     */
    function getCurrentRoot() external view override returns (bytes32) {
        return currentRoot;
    }

    /**
     * @inheritdoc IReputationCore
     */
    function getCurrentEpoch() external view override returns (uint256) {
        return currentEpoch;
    }

    /**
     * @inheritdoc IReputationCore
     */
    function getRootAtEpoch(uint256 epoch) external view override returns (bytes32) {
        return epochRoots[epoch];
    }

    /**
     * @inheritdoc IReputationCore
     */
    function isValidRoot(bytes32 root) external view override returns (bool) {
        return validRoots[root];
    }

    /**
     * @inheritdoc IReputationCore
     */
    function advanceEpoch() external override onlyGuardian {
        require(
            block.timestamp >= lastEpochTransition + EPOCH_DURATION,
            "Epoch duration not elapsed"
        );

        uint256 oldEpoch = currentEpoch;
        currentEpoch++;
        lastEpochTransition = block.timestamp;

        // Carry forward current root to new epoch
        epochRoots[currentEpoch] = currentRoot;

        emit EpochTransitioned(oldEpoch, currentEpoch);
    }

    /**
     * @notice Update guardian address
     * @param newGuardian New guardian address
     */
    function updateGuardian(address newGuardian) external onlyGuardian {
        require(newGuardian != address(0), "Invalid guardian address");
        guardian = newGuardian;
    }

    /**
     * @notice Update oracle address
     * @param newOracle New oracle address
     */
    function updateOracle(address newOracle) external onlyGuardian {
        require(newOracle != address(0), "Invalid oracle address");
        oracle = newOracle;
    }

    /**
     * @notice Get time until next epoch
     * @return uint256 Seconds until next epoch can be started
     */
    function timeUntilNextEpoch() external view returns (uint256) {
        uint256 nextEpochTime = lastEpochTransition + EPOCH_DURATION;
        if (block.timestamp >= nextEpochTime) {
            return 0;
        }
        return nextEpochTime - block.timestamp;
    }
}

// Cache optimization
