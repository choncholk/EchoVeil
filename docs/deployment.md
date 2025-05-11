# Deployment Guide

## Prerequisites

- Foundry installed
- Deployer private key
- RPC URL for target network

## Steps

1. Configure environment variables
2. Run deployment script
3. Verify contracts
4. Update contract addresses

## Commands

```bash
# Deploy to testnet
forge script scripts/Deploy.s.sol --rpc-url $TESTNET_RPC --broadcast

# Verify
./scripts/verify_contracts.sh
```

Deployment checklist
