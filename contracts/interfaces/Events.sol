// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Events {
    event IdentityRegistered(address indexed user, bytes32 indexed identityHash, uint256 timestamp);
    event NullifierConsumed(bytes32 indexed nullifier, address indexed user);
    event RootUpdated(uint256 indexed epoch, bytes32 indexed newRoot, bytes32 previousRoot, uint256 timestamp);
    event EpochTransitioned(uint256 oldEpoch, uint256 newEpoch);
    event ProofVerified(address indexed verifier, bool success, uint256 timestamp);
    event EligibilityVerified(address indexed user, bool success, bytes32 indexed nullifier, uint256 timestamp);
}

