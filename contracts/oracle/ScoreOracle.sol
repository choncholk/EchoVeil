// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IReputationCore.sol";

/**
 * @title ScoreOracle
 * @notice Off-chain score aggregator with on-chain Merkle root commitment
 * @dev Securely updates reputation Merkle roots with rate limiting and timelock
 */
contract ScoreOracle {
    /// @notice Reputation Core contract
    IReputationCore public immutable reputationCore;

    /// @notice Oracle operator address
    address public operator;

    /// @notice Guardian address for emergency controls
    address public guardian;

    /// @notice Minimum time between root updates
    uint256 public constant UPDATE_COOLDOWN = 1 days;

    /// @notice Last update timestamp
    uint256 public lastUpdateTimestamp;

    /// @notice Pending root update
    struct PendingUpdate {
        bytes32 newRoot;
        uint256 timestamp;
        bool executed;
    }

    /// @notice Current pending update
    PendingUpdate public pendingUpdate;

    /// @notice Timelock delay for root updates
    uint256 public constant TIMELOCK_DELAY = 1 hours;

    /// @notice Emergency pause flag
    bool public paused;

    /**
     * @notice Emitted when a root update is proposed
     */
    event RootUpdateProposed(
        bytes32 indexed newRoot,
        uint256 timestamp,
        address operator
    );

    /**
     * @notice Emitted when a root update is executed
     */
    event RootUpdateExecuted(bytes32 indexed newRoot, uint256 timestamp);

    /**
     * @notice Emitted when oracle is paused
     */
    event OraclePaused(address guardian, uint256 timestamp);

    /**
     * @notice Emitted when oracle is unpaused
     */
    event OracleUnpaused(address guardian, uint256 timestamp);

    /**
     * @notice Only operator can call
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator");
        _;
    }

    /**
     * @notice Only guardian can call
     */
    modifier onlyGuardian() {
        require(msg.sender == guardian, "Only guardian");
        _;
    }

    /**
     * @notice Only when not paused
     */
    modifier whenNotPaused() {
        require(!paused, "Oracle is paused");
        _;
    }

    /**
     * @notice Constructor
     * @param _reputationCore Address of ReputationCore
     * @param _operator Oracle operator address
     * @param _guardian Guardian address
     */
    constructor(
        address _reputationCore,
        address _operator,
        address _guardian
    ) {
        require(_reputationCore != address(0), "Invalid reputation core");
        require(_operator != address(0), "Invalid operator");
        require(_guardian != address(0), "Invalid guardian");

        reputationCore = IReputationCore(_reputationCore);
        operator = _operator;
        guardian = _guardian;
        lastUpdateTimestamp = block.timestamp;
    }

    /**
     * @notice Propose a new Merkle root update
     * @param newRoot New Merkle root to commit
     */
    function proposeRootUpdate(
        bytes32 newRoot
    ) external onlyOperator whenNotPaused {
        require(newRoot != bytes32(0), "Invalid root");
        require(
            block.timestamp >= lastUpdateTimestamp + UPDATE_COOLDOWN,
            "Update cooldown not elapsed"
        );
        require(!pendingUpdate.executed, "Pending update exists");

        pendingUpdate = PendingUpdate({
            newRoot: newRoot,
            timestamp: block.timestamp,
            executed: false
        });

        emit RootUpdateProposed(newRoot, block.timestamp, msg.sender);
    }

    /**
     * @notice Execute a pending root update after timelock
     */
    function executeRootUpdate() external onlyOperator whenNotPaused {
        require(pendingUpdate.newRoot != bytes32(0), "No pending update");
        require(!pendingUpdate.executed, "Already executed");
        require(
            block.timestamp >= pendingUpdate.timestamp + TIMELOCK_DELAY,
            "Timelock not elapsed"
        );

        bytes32 newRoot = pendingUpdate.newRoot;
        pendingUpdate.executed = true;
        lastUpdateTimestamp = block.timestamp;

        // Update the reputation core
        reputationCore.updateRoot(newRoot);

        emit RootUpdateExecuted(newRoot, block.timestamp);

        // Clear pending update
        delete pendingUpdate;
    }

    /**
     * @notice Emergency root update by guardian (bypasses timelock)
     * @param newRoot New Merkle root
     */
    function emergencyUpdateRoot(bytes32 newRoot) external onlyGuardian {
        require(newRoot != bytes32(0), "Invalid root");

        reputationCore.updateRoot(newRoot);
        lastUpdateTimestamp = block.timestamp;

        // Clear any pending update
        delete pendingUpdate;

        emit RootUpdateExecuted(newRoot, block.timestamp);
    }

    /**
     * @notice Pause the oracle
     */
    function pause() external onlyGuardian {
        paused = true;
        emit OraclePaused(msg.sender, block.timestamp);
    }

    /**
     * @notice Unpause the oracle
     */
    function unpause() external onlyGuardian {
        paused = false;
        emit OracleUnpaused(msg.sender, block.timestamp);
    }

    /**
     * @notice Update operator address
     * @param newOperator New operator address
     */
    function updateOperator(address newOperator) external onlyGuardian {
        require(newOperator != address(0), "Invalid operator");
        operator = newOperator;
    }

    /**
     * @notice Transfer guardian role
     * @param newGuardian New guardian address
     */
    function transferGuardian(address newGuardian) external onlyGuardian {
        require(newGuardian != address(0), "Invalid guardian");
        guardian = newGuardian;
    }

    /**
     * @notice Get time until next update is allowed
     * @return uint256 Seconds until next update
     */
    function timeUntilNextUpdate() external view returns (uint256) {
        uint256 nextUpdateTime = lastUpdateTimestamp + UPDATE_COOLDOWN;
        if (block.timestamp >= nextUpdateTime) {
            return 0;
        }
        return nextUpdateTime - block.timestamp;
    }

    /**
     * @notice Get time until pending update can be executed
     * @return uint256 Seconds until execution
     */
    function timeUntilExecution() external view returns (uint256) {
        if (pendingUpdate.newRoot == bytes32(0) || pendingUpdate.executed) {
            return 0;
        }
        uint256 executionTime = pendingUpdate.timestamp + TIMELOCK_DELAY;
        if (block.timestamp >= executionTime) {
            return 0;
        }
        return executionTime - block.timestamp;
    }
}

