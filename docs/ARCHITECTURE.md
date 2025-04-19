# EchoVeil Architecture

## System Overview

EchoVeil is a privacy-preserving reputation protocol built on zero-knowledge proofs. The system enables users to prove their reputation scores and eligibility for various activities without revealing their identity or transaction history.

## Core Components

### 1. Identity Registry

**Purpose**: Manages user identity commitments and prevents Sybil attacks

**Key Features**:
- Zero-knowledge identity registration
- Nullifier tracking for replay protection
- One identity per address enforcement

**Smart Contract**: `IdentityRegistry.sol`

### 2. Reputation Core

**Purpose**: Stores and manages Merkle roots of reputation trees

**Key Features**:
- Epoch-based reputation snapshots
- Guardian-protected root updates
- Historical root preservation

**Smart Contract**: `ReputationCore.sol`

### 3. ZK Verifier

**Purpose**: On-chain verification of zero-knowledge proofs

**Key Features**:
- Groth16 proof verification
- Multiple proof types support
- Circuit version management

**Smart Contract**: `ZKVerifier.sol`

**Circuit**: `circuits/reputation_proof.circom`

### 4. Proof Gateway

**Purpose**: Unified interface for dApp integrations

**Key Features**:
- Standardized verification API
- Batch proof verification
- dApp registration system

**Smart Contract**: `ProofGateway.sol`

### 5. Score Oracle

**Purpose**: Off-chain score aggregation and on-chain commitment

**Key Features**:
- Timelock-protected updates
- Rate limiting (1 update per day)
- Emergency pause mechanism

**Smart Contract**: `ScoreOracle.sol`

### 6. Guardian Multisig

**Purpose**: Decentralized governance and emergency controls

**Key Features**:
- Multi-signature transactions
- Threshold-based execution
- Emergency pause capability

**Smart Contract**: `GuardianMultisig.sol`

## Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                         User Actions                         │
│              (transactions, interactions, etc.)              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Off-Chain Aggregator                      │
│        Collects data, computes scores, builds Merkle tree   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                      Score Oracle                            │
│           Commits Merkle root on-chain (timelock)           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Reputation Core                           │
│              Stores current and historical roots             │
└─────────────────────────────────────────────────────────────┘

                  User generates ZK proof
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                     Proof Gateway                            │
│              Coordinates verification process                │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                      ZK Verifier                             │
│                Validates proof on-chain                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   Identity Registry                          │
│             Checks nullifier, prevents replay                │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                 dApp Consumes Result                         │
│      (airdrop, voting, lending, allowlist, etc.)            │
└─────────────────────────────────────────────────────────────┘
```

## Security Model

### Threat Mitigation

1. **Sybil Attacks**: Prevented by nullifier-based identity binding
2. **Replay Attacks**: Nullifiers are consumed after first use
3. **Front-running**: Commitments use private secrets
4. **Oracle Manipulation**: Timelock + guardian oversight
5. **Admin Abuse**: Multi-signature guardian with threshold

### Trust Assumptions

- **Guardian Multisig**: Trusted for emergency actions and root updates
- **Oracle Operator**: Trusted for score computation (off-chain)
- **ZK Circuit**: Trusted setup via MPC ceremony
- **Smart Contracts**: Open source, audited, immutable

## Proof System

### Circuit: Reputation Proof

**Public Inputs**:
- Merkle root (current reputation tree root)
- Threshold (minimum required score)
- Nullifier (prevents double-use)

**Private Inputs**:
- Identity secret
- Actual score
- Merkle path (proof of inclusion)

**Circuit Logic**:
1. Compute identity commitment from secret
2. Derive nullifier from identity secret
3. Verify score ≥ threshold
4. Verify Merkle inclusion proof
5. Output validity signal

### Groth16 Proof

- **Proving time**: ~5 seconds (client-side)
- **Verification gas**: ~250,000 gas
- **Security level**: 128-bit

## Integration Guide

### For dApps

```solidity
// 1. Import interface
import "echoveil/interfaces/IProofGateway.sol";

// 2. Create requirement
IProofGateway.EligibilityRequirement memory requirement = 
    IProofGateway.EligibilityRequirement({
        merkleRoot: currentRoot,
        minScore: 100,
        maxScore: type(uint256).max,
        epoch: currentEpoch,
        requireSybilResistance: true
    });

// 3. Verify proof
IProofGateway.VerificationResult memory result = 
    proofGateway.verifyEligibility(proof, requirement, nullifier);

// 4. Check result
require(result.success, "Proof verification failed");
```

### For Users

```javascript
// 1. Generate proof off-chain
const proof = await generateProof({
    identitySecret: userSecret,
    score: userScore,
    merklePath: path,
    threshold: 100
});

// 2. Submit to gateway
const tx = await proofGateway.verifyEligibility(
    proof,
    requirement,
    nullifier
);

// 3. Access dApp feature
await dapp.claimAirdrop(tx.nullifier);
```

## Deployment

### Contracts Deployment Order

1. **GuardianMultisig** - governance first
2. **ZKVerifier** - proof verification
3. **IdentityRegistry** - identity management
4. **ReputationCore** - reputation state
5. **ScoreOracle** - oracle system
6. **ProofGateway** - integration layer

### Configuration

- Set guardian multisig members
- Configure oracle operator
- Initialize Merkle root
- Set epoch duration
- Configure timelock delays

## Future Enhancements

### Planned Features

- **SBT Mode**: Non-transferable reputation tokens (ERC-4973)
- **DAO Voting**: Anonymous voting with reputation weight
- **zkTLS Integration**: Import Web2 credentials
- **Cross-Chain**: LayerZero bridge for multi-chain reputation
- **Delegation**: Reputation lending without revealing identity
- **Decay Mechanism**: Time-based reputation decay

### Research Areas

- **Recursive SNARKs**: Proof aggregation for batch verification
- **PLONK Migration**: Universal setup, no trusted ceremony
- **Halo2 Support**: Transparent setup alternative
- **On-chain Prover**: L2 native proof generation

## Performance

### Gas Costs (Estimated)

| Operation | Gas Cost |
|-----------|----------|
| Register Identity | ~150,000 |
| Update Root | ~80,000 |
| Verify Proof | ~250,000 |
| Consume Nullifier | ~45,000 |
| Advance Epoch | ~60,000 |

### Scalability

- **Current**: ~100 verifications per block
- **Optimized**: ~500 with batch verification
- **L2 Native**: ~5,000 on zkEVM/zkSync

## References

- [Groth16 Paper](https://eprint.iacr.org/2016/260.pdf)
- [Circom Documentation](https://docs.circom.io/)
- [Merkle Tree Proofs](https://ethereum.org/en/developers/tutorials/merkle-proofs-for-offline-data-integrity/)
- [Sismo Protocol](https://docs.sismo.io/)

Architecture improvements
