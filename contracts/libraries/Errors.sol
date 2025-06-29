// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Errors
 * @notice Library for custom error definitions
 * @dev Centralized error definitions for gas-efficient reverts
 */
library Errors {
    // Identity Registry Errors
    error InvalidIdentityHash();
    error IdentityAlreadyRegistered();
    error IdentityNotRegistered();
    error InvalidProofData();
    error NullifierAlreadyUsed();

    // Reputation Core Errors
    error InvalidRoot();
    error RootUnchanged();
    error EpochDurationNotElapsed();
    error InvalidEpoch();
    error OnlyGuardian();
    error OnlyOracleOrGuardian();

    // ZK Verifier Errors
    error InvalidProofPointA();
    error InvalidProofPointB();
    error InvalidProofPointC();
    error NoPublicSignals();
    error InvalidThreshold();
    error ProofVerificationFailed();

    // Proof Gateway Errors
    error InvalidNullifier();
    error NullifierUsed();
    error InvalidMerkleRoot();
    error ArrayLengthMismatch();
    error DAppAlreadyRegistered();
    error DAppNotRegistered();
    error InvalidMetadata();

    // Oracle Errors
    error OnlyOperator();
    error OraclePaused();
    error UpdateCooldownNotElapsed();
    error PendingUpdateExists();
    error NoPendingUpdate();
    error TimelockNotElapsed();
    error AlreadyExecuted();

    // Multisig Errors
    error NotGuardian();
    error TransactionDoesNotExist();
    error TransactionAlreadyExecuted();
    error TransactionAlreadyConfirmed();
    error TransactionNotConfirmed();
    error InsufficientConfirmations();
    error TransactionExecutionFailed();

    // General Errors
    error InvalidAddress();
    error ZeroAddress();
    error InvalidAmount();
    error InsufficientBalance();
    error Unauthorized();
    error InvalidParameter();
    error OperationNotAllowed();
}

// Error handling improvements
