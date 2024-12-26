#!/bin/bash
# Setup testnet deployment

set -e

echo "Setting up EchoVeil on testnet..."

# Deploy contracts
forge script scripts/Deploy.s.sol \
    --rpc-url $TESTNET_RPC_URL \
    --broadcast \
    --verify

echo "Testnet deployment complete!"

