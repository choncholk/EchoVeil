#!/bin/bash

# Contract verification script for Etherscan/Polygonscan

set -e

NETWORK=${1:-polygon-zkevm}
CHAIN_ID=${2:-1101}

echo "=== EchoVeil Contract Verification ==="
echo "Network: $NETWORK"
echo "Chain ID: $CHAIN_ID"
echo ""

# Load deployment addresses
source deployment.txt

# Verify contracts
echo "Verifying GuardianMultisig..."
forge verify-contract \
    --chain-id $CHAIN_ID \
    --constructor-args $(cast abi-encode "constructor(address[],uint256)" "[$GUARDIAN_ADDRESS]" 2) \
    $GUARDIAN_MULTISIG \
    contracts/governance/GuardianMultisig.sol:GuardianMultisig

echo "Verifying ZKVerifier..."
forge verify-contract \
    --chain-id $CHAIN_ID \
    --constructor-args $(cast abi-encode "constructor(bytes32,bool)" $(cast keccak "echoveil_circuit_v1") false) \
    $ZK_VERIFIER \
    contracts/core/ZKVerifier.sol:ZKVerifier

echo "Verifying IdentityRegistry..."
forge verify-contract \
    --chain-id $CHAIN_ID \
    --constructor-args $(cast abi-encode "constructor(address)" $ZK_VERIFIER) \
    $IDENTITY_REGISTRY \
    contracts/core/IdentityRegistry.sol:IdentityRegistry

echo "Verifying ReputationCore..."
forge verify-contract \
    --chain-id $CHAIN_ID \
    $REPUTATION_CORE \
    contracts/core/ReputationCore.sol:ReputationCore

echo "Verifying ScoreOracle..."
forge verify-contract \
    --chain-id $CHAIN_ID \
    $SCORE_ORACLE \
    contracts/oracle/ScoreOracle.sol:ScoreOracle

echo "Verifying ProofGateway..."
forge verify-contract \
    --chain-id $CHAIN_ID \
    $PROOF_GATEWAY \
    contracts/core/ProofGateway.sol:ProofGateway

echo ""
echo "Verification complete!"

