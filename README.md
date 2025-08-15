# EchoVeil

**Privacy-Preserving ZK Reputation Layer for Web3**

## Overview

EchoVeil is a zero-knowledge reputation protocol that enables users to prove trustworthiness, Sybil-resistance, and historical credibility without revealing wallet identity, activity logs, or social graph.

## Key Features

- 🔐 **Zero-Knowledge Proof**: Prove reputation score without revealing transaction history
- 🛡️ **Sybil-Resistant**: Nullifier-based identity binding prevents fake accounts
- 🎯 **Anonymous Eligibility**: Verify qualifications for airdrops, DAOs, and allowlists privately
- 🌐 **Cross-Platform**: Export portable reputation proofs across dApps
- ⏰ **Epoch-Based Updates**: Time-locked reputation refresh via decentralized oracle

## Architecture

```
[User Wallet] → [IdentityRegistry] → [ReputationCore] ← [ScoreOracle]
                                            ↓
                    [ZKVerifier] ← [ZK Circuit (Circom/Halo2)]
                                            ↓
                    [ProofGateway] → [dApps/DAOs/Lenders]
```

## Tech Stack

- **Smart Contracts**: Solidity, Foundry, OpenZeppelin
- **ZK Circuits**: Circom, snarkjs, Groth16
- **Target Chains**: Polygon zkEVM, ZKsync
- **Indexing**: The Graph
- **Security**: Slither, Foundry Fuzzing

## Project Structure

```
contracts/          # Solidity smart contracts
circuits/           # ZK circuits (Circom)
scripts/            # Deployment and helper scripts
test/               # Contract and circuit tests
docs/               # Documentation
```

## Getting Started

```bash
# Install dependencies
npm install

# Compile contracts
forge build

# Run tests
forge test

# Deploy
forge script scripts/Deploy.s.sol --rpc-url <RPC_URL>
```

## License

MIT License - see [LICENSE](LICENSE) for details

## Status

🚧 **Under Active Development** 🚧

Updated README with final touches
Final project polish complete
