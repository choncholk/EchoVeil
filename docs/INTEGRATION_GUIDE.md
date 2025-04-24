# EchoVeil Integration Guide

## Quick Start

This guide will help you integrate EchoVeil's privacy-preserving reputation system into your dApp.

## Overview

EchoVeil enables your users to prove their reputation without revealing their identity or transaction history. Use cases include:

- 🎁 **Airdrops**: Distribute tokens to users with high reputation
- 🗳️ **DAO Voting**: Anonymous voting weighted by reputation
- 💰 **Lending**: Credit scoring without KYC
- 🎫 **Allowlists**: Reputation-gated access
- 🏆 **Rewards**: Merit-based distributions

## Integration Steps

### Step 1: Install Dependencies

```bash
npm install echoveil-sdk ethers
```

### Step 2: Import Interfaces

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "echoveil/interfaces/IProofGateway.sol";
import "echoveil/interfaces/IZKVerifier.sol";
import "echoveil/interfaces/IReputationCore.sol";
```

### Step 3: Initialize Contracts

```solidity
contract MyDApp {
    IProofGateway public immutable proofGateway;
    IReputationCore public immutable reputationCore;
    
    constructor(address _proofGateway, address _reputationCore) {
        proofGateway = IProofGateway(_proofGateway);
        reputationCore = IReputationCore(_reputationCore);
    }
}
```

### Step 4: Define Requirements

```solidity
function createRequirement(uint256 minScore) 
    internal 
    view 
    returns (IProofGateway.EligibilityRequirement memory) 
{
    return IProofGateway.EligibilityRequirement({
        merkleRoot: reputationCore.getCurrentRoot(),
        minScore: minScore,
        maxScore: type(uint256).max,
        epoch: reputationCore.getCurrentEpoch(),
        requireSybilResistance: true
    });
}
```

### Step 5: Verify Proofs

```solidity
function verifyUser(
    IZKVerifier.Proof calldata proof,
    bytes32 nullifier
) external {
    IProofGateway.EligibilityRequirement memory requirement = 
        createRequirement(100); // Min score: 100
    
    IProofGateway.VerificationResult memory result = 
        proofGateway.verifyEligibility(proof, requirement, nullifier);
    
    require(result.success, "Verification failed");
    
    // Grant access to user
    // ...
}
```

## Use Case Examples

### 1. Reputation-Gated Airdrop

```solidity
contract ReputationAirdrop {
    IProofGateway public proofGateway;
    mapping(bytes32 => bool) public claimed;
    
    uint256 public constant MIN_REPUTATION = 100;
    uint256 public constant AIRDROP_AMOUNT = 1000 ether;
    
    function claimAirdrop(
        IZKVerifier.Proof calldata proof,
        bytes32 nullifier
    ) external {
        require(!claimed[nullifier], "Already claimed");
        
        // Create requirement
        IProofGateway.EligibilityRequirement memory req = 
            IProofGateway.EligibilityRequirement({
                merkleRoot: getCurrentMerkleRoot(),
                minScore: MIN_REPUTATION,
                maxScore: type(uint256).max,
                epoch: getCurrentEpoch(),
                requireSybilResistance: true
            });
        
        // Verify proof
        IProofGateway.VerificationResult memory result = 
            proofGateway.verifyEligibility(proof, req, nullifier);
        
        require(result.success, "Verification failed");
        
        // Mark as claimed
        claimed[nullifier] = true;
        
        // Transfer tokens
        token.transfer(msg.sender, AIRDROP_AMOUNT);
    }
}
```

### 2. Anonymous DAO Voting

```solidity
contract ReputationDAO {
    struct Proposal {
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 deadline;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(bytes32 => bool)) public hasVoted;
    
    function vote(
        uint256 proposalId,
        bool support,
        IZKVerifier.Proof calldata proof,
        bytes32 nullifier
    ) external {
        require(!hasVoted[proposalId][nullifier], "Already voted");
        require(block.timestamp < proposals[proposalId].deadline, "Voting ended");
        
        // Verify voter has minimum reputation
        IProofGateway.EligibilityRequirement memory req = 
            createRequirement(50); // Min score: 50
        
        IProofGateway.VerificationResult memory result = 
            proofGateway.verifyEligibility(proof, req, nullifier);
        
        require(result.success, "Insufficient reputation");
        
        // Record vote
        hasVoted[proposalId][nullifier] = true;
        
        if (support) {
            proposals[proposalId].yesVotes++;
        } else {
            proposals[proposalId].noVotes++;
        }
    }
}
```

### 3. Reputation-Based Lending

```solidity
contract ReputationLending {
    mapping(bytes32 => uint256) public creditLimits;
    
    function getCreditLimit(
        IZKVerifier.Proof calldata proof,
        bytes32 nullifier,
        uint256 claimedScore
    ) external returns (uint256) {
        // Verify score claim
        IProofGateway.EligibilityRequirement memory req = 
            IProofGateway.EligibilityRequirement({
                merkleRoot: getCurrentMerkleRoot(),
                minScore: claimedScore,
                maxScore: type(uint256).max,
                epoch: getCurrentEpoch(),
                requireSybilResistance: true
            });
        
        IProofGateway.VerificationResult memory result = 
            proofGateway.verifyEligibility(proof, req, nullifier);
        
        require(result.success, "Score verification failed");
        
        // Calculate credit limit based on score
        uint256 creditLimit = calculateCredit(claimedScore);
        creditLimits[nullifier] = creditLimit;
        
        return creditLimit;
    }
    
    function calculateCredit(uint256 score) internal pure returns (uint256) {
        // Example: 10 ETH per 100 reputation points
        return (score * 10 ether) / 100;
    }
}
```

## Client-Side Integration

### 1. Setup SDK

```javascript
import { EchoVeilClient } from 'echoveil-sdk';

const client = new EchoVeilClient({
    network: 'polygon-zkevm',
    proofGatewayAddress: '0x...',
    reputationCoreAddress: '0x...'
});
```

### 2. Generate Identity

```javascript
// Generate new identity secret (store securely!)
const identitySecret = client.generateIdentitySecret();

// Compute identity commitment
const identityCommitment = client.computeCommitment(identitySecret);

// Register identity on-chain
await client.registerIdentity(identityCommitment, zkProof);
```

### 3. Generate Proof

```javascript
// Get user's reputation data
const userData = await client.getUserReputation(identityCommitment);

// Generate ZK proof
const proof = await client.generateProof({
    identitySecret: identitySecret,
    score: userData.score,
    merkleRoot: userData.merkleRoot,
    threshold: 100,
    merklePath: userData.merklePath
});

// Submit proof to your dApp
await myDApp.verifyUser(proof.solidityProof, proof.nullifier);
```

### 4. Check Eligibility

```javascript
// Check if user meets requirement without generating proof
const isEligible = await client.checkEligibility({
    userScore: userData.score,
    requiredScore: 100
});

if (isEligible) {
    // Generate and submit proof
    const proof = await client.generateProof(/* ... */);
    await submitProof(proof);
}
```

## Advanced Features

### Batch Verification

Verify multiple users in one transaction:

```solidity
function verifyBatch(
    IZKVerifier.Proof[] calldata proofs,
    IProofGateway.EligibilityRequirement[] calldata requirements,
    bytes32[] calldata nullifiers
) external {
    IProofGateway.VerificationResult[] memory results = 
        proofGateway.batchVerifyEligibility(proofs, requirements, nullifiers);
    
    for (uint256 i = 0; i < results.length; i++) {
        require(results[i].success, "Batch verification failed");
        // Process each result
    }
}
```

### Dynamic Score Thresholds

Adjust requirements based on conditions:

```solidity
function getDynamicRequirement() internal view returns (uint256) {
    if (block.timestamp < earlyAccessDeadline) {
        return 500; // Higher requirement for early access
    } else {
        return 100; // Lower requirement after deadline
    }
}
```

### Score Range Verification

Verify score is within a range:

```solidity
IProofGateway.EligibilityRequirement memory req = 
    IProofGateway.EligibilityRequirement({
        merkleRoot: currentRoot,
        minScore: 100,
        maxScore: 500, // Maximum score
        epoch: currentEpoch,
        requireSybilResistance: true
    });
```

## Testing

### Foundry Tests

```solidity
import "forge-std/Test.sol";

contract MyDAppTest is Test {
    MyDApp public dapp;
    IProofGateway public proofGateway;
    
    function setUp() public {
        // Deploy test contracts
        proofGateway = deployMockProofGateway();
        dapp = new MyDApp(address(proofGateway));
    }
    
    function testVerifyUser() public {
        // Create mock proof
        IZKVerifier.Proof memory proof = createMockProof();
        bytes32 nullifier = keccak256("test_nullifier");
        
        // Test verification
        dapp.verifyUser(proof, nullifier);
    }
}
```

### JavaScript Tests

```javascript
const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('MyDApp Integration', () => {
    it('should verify reputation proof', async () => {
        const MyDApp = await ethers.getContractFactory('MyDApp');
        const dapp = await MyDApp.deploy(proofGatewayAddress);
        
        const proof = await generateMockProof();
        const nullifier = ethers.utils.keccak256('0x1234');
        
        await expect(dapp.verifyUser(proof, nullifier))
            .to.emit(dapp, 'UserVerified');
    });
});
```

## Gas Optimization Tips

1. **Batch operations** when possible
2. **Cache** Merkle root and epoch in storage
3. **Use events** instead of storage for logs
4. **Optimize** requirement structures
5. **Deploy on L2** (zkEVM/zkSync) for lower costs

## Security Checklist

- [ ] Always verify proofs through ProofGateway
- [ ] Track nullifiers to prevent replay attacks
- [ ] Use current epoch and Merkle root
- [ ] Set appropriate score thresholds
- [ ] Handle verification failures gracefully
- [ ] Emit events for auditability
- [ ] Test edge cases thoroughly
- [ ] Consider rate limiting for Sybil protection

## Deployed Contracts

### Polygon zkEVM Mainnet

```
ProofGateway: 0x...
ReputationCore: 0x...
ZKVerifier: 0x...
IdentityRegistry: 0x...
```

### zkSync Era Mainnet

```
ProofGateway: 0x...
ReputationCore: 0x...
ZKVerifier: 0x...
IdentityRegistry: 0x...
```

### Testnet

```
ProofGateway: 0x...
ReputationCore: 0x...
ZKVerifier: 0x...
IdentityRegistry: 0x...
```

## Support

- **Documentation**: https://docs.echoveil.io
- **Discord**: https://discord.gg/echoveil
- **GitHub**: https://github.com/echoveil/protocol
- **Twitter**: @EchoVeil

## Examples

Full working examples available at:
- [Airdrop Example](../contracts/examples/AirdropExample.sol)
- [DAO Voting Example](../contracts/examples/DAOVotingExample.sol)

## Next Steps

1. Review the [Architecture Documentation](./ARCHITECTURE.md)
2. Study the [API Reference](./API.md)
3. Check [Security Best Practices](./SECURITY.md)
4. Join our [Discord](https://discord.gg/echoveil) for support

Happy building! 🚀

Integration examples
