// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Constants
 * @notice Protocol-wide constants
 */
library Constants {
    uint256 constant EPOCH_DURATION = 1 days;
    uint256 constant UPDATE_COOLDOWN = 1 days;
    uint256 constant TIMELOCK_DELAY = 1 hours;
    uint256 constant MIN_PROOF_AGE = 1 hours;
    uint256 constant MAX_HISTORICAL_EPOCHS = 100;
    uint256 constant TREE_LEVELS = 20;
    uint256 constant MAX_LEAVES = 2 ** 20;
    bytes32 constant ZERO_BYTES32 = bytes32(0);
}

// Constants update
