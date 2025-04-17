# Security Policy

## Overview

EchoVeil is a privacy-preserving reputation protocol that relies on zero-knowledge proofs and cryptographic commitments. This document outlines our security model, known risks, and disclosure policy.

## Security Model

### Trust Assumptions

1. **Guardian Multisig**
   - Trusted for emergency actions and system upgrades
   - Threshold signature required for critical operations
   - Should be operated by diverse, reputable entities

2. **Oracle Operator**
   - Trusted for off-chain score computation
   - Subject to timelock and cooldown periods
   - Guardian can override in emergencies

3. **ZK Circuit**
   - Trusted setup via multi-party computation (MPC)
   - Circuit logic is public and auditable
   - Verifying key hash committed on-chain

4. **Smart Contracts**
   - Open source and audited
   - Immutable after deployment (no proxies)
   - Pausable for emergency scenarios

### Threat Model

#### In-Scope Threats

1. **Sybil Attacks**
   - **Mitigation**: Nullifier-based identity binding
   - One proof per identity per epoch
   - Nullifiers are consumed after use

2. **Replay Attacks**
   - **Mitigation**: Single-use nullifiers
   - On-chain nullifier registry
   - Per-epoch commitment roots

3. **Front-running**
   - **Mitigation**: Private identity secrets
   - Commitments hide actual values
   - No MEV-exploitable transactions

4. **Oracle Manipulation**
   - **Mitigation**: Timelock delays
   - Rate limiting (1 update per day)
   - Guardian oversight and rollback capability

5. **Smart Contract Vulnerabilities**
   - **Mitigation**: Comprehensive testing
   - External security audits
   - Foundry fuzz testing
   - Formal verification (planned)

6. **Proof Forgery**
   - **Mitigation**: Groth16 security guarantees
   - Proper circuit constraints
   - Verifying key integrity checks

#### Out-of-Scope Threats

1. Breaking elliptic curve cryptography (BN128)
2. Breaking Poseidon hash function
3. Compromising all guardian multisig members
4. 51% attacks on underlying blockchain
5. Quantum computing attacks (post-quantum migration planned)

## Known Issues

### Current Limitations

1. **Simplified Verifier**
   - Current implementation uses simplified pairing checks
   - Production deployment requires circom-generated verifier
   - Proper trusted setup ceremony needed

2. **Gas Costs**
   - Proof verification costs ~250k gas
   - May be expensive on L1
   - Recommended for L2 deployment (zkEVM/zkSync)

3. **Circuit Complexity**
   - Current circuit supports 20-level Merkle trees (1M users)
   - Larger trees require circuit recompilation
   - Proving time increases with tree depth

4. **Epoch Transitions**
   - Manual epoch advancement required
   - Not yet automated via time-based triggers
   - Guardian must call `advanceEpoch()`

5. **Off-chain Dependencies**
   - Reputation scoring happens off-chain
   - Users need to run proof generation locally
   - Prover-as-a-service planned but not implemented

## Audit Status

### Planned Audits

- [ ] Internal security review
- [ ] External audit by reputable firm
- [ ] Bug bounty program launch
- [ ] Formal verification of critical functions

### Past Audits

None yet - protocol is in active development.

## Bug Bounty Program

### Coming Soon

We plan to launch a bug bounty program after initial audit completion.

**Estimated Rewards**:
- Critical: Up to $50,000
- High: Up to $25,000
- Medium: Up to $10,000
- Low: Up to $2,500

### Scope

**In Scope**:
- Smart contracts in `contracts/core/`
- Smart contracts in `contracts/oracle/`
- Smart contracts in `contracts/governance/`
- ZK circuits in `circuits/`

**Out of Scope**:
- Example contracts in `contracts/examples/`
- Test files
- Documentation
- Scripts and utilities

## Responsible Disclosure

### Reporting Security Issues

**DO NOT** create public GitHub issues for security vulnerabilities.

Instead, please report vulnerabilities via:

**Email**: security@echoveil.io (coming soon)

**PGP Key**: [To be provided]

**Include**:
1. Description of the vulnerability
2. Steps to reproduce
3. Potential impact
4. Suggested fix (if any)

### Response Timeline

- **24 hours**: Initial response acknowledging receipt
- **72 hours**: Assessment of severity and validity
- **7 days**: Preliminary fix or mitigation plan
- **30 days**: Fix deployed (for critical issues)
- **90 days**: Public disclosure (coordinated)

### Recognition

Security researchers who responsibly disclose vulnerabilities will be:
- Listed in our Hall of Fame (with permission)
- Eligible for bug bounty rewards
- Credited in release notes

## Best Practices for Integrators

### dApp Developers

1. **Always verify proofs through ProofGateway**
   ```solidity
   IProofGateway.VerificationResult memory result = 
       proofGateway.verifyEligibility(proof, requirement, nullifier);
   require(result.success, "Verification failed");
   ```

2. **Check nullifier uniqueness**
   ```solidity
   require(!hasUsed[nullifier], "Nullifier already used");
   hasUsed[nullifier] = true;
   ```

3. **Use current epoch and root**
   ```solidity
   bytes32 currentRoot = reputationCore.getCurrentRoot();
   uint256 currentEpoch = reputationCore.getCurrentEpoch();
   ```

4. **Set appropriate score thresholds**
   - Don't set thresholds too low (Sybil risk)
   - Don't set thresholds too high (exclusion risk)
   - Consider your use case requirements

### Users

1. **Keep identity secret secure**
   - Store in secure, encrypted location
   - Never share with anyone
   - Back up securely

2. **Verify contract addresses**
   - Check official documentation
   - Use verified contracts only
   - Be wary of phishing

3. **Generate proofs locally**
   - Don't send secrets to third parties
   - Use official proof generation tools
   - Verify circuit hashes

### Oracle Operators

1. **Secure score computation**
   - Use deterministic algorithms
   - Maintain audit logs
   - Implement access controls

2. **Follow update procedures**
   - Respect cooldown periods
   - Wait for timelock delays
   - Document all updates

3. **Monitor for anomalies**
   - Watch for unusual patterns
   - Implement alerting
   - Have rollback procedures

## Emergency Procedures

### Guardian Actions

**Scenario: Oracle Compromise**
```solidity
// 1. Pause oracle
scoreOracle.pause();

// 2. Emergency update to rollback
scoreOracle.emergencyUpdateRoot(previousValidRoot);

// 3. Investigate and fix
```

**Scenario: Contract Bug**
```solidity
// 1. Trigger emergency pause via multisig
guardianMultisig.triggerEmergencyPause();

// 2. Deploy fixed contracts
// 3. Coordinate migration
```

### User Actions

**Scenario: Suspected Compromise**
1. Stop generating proofs immediately
2. Contact team via official channels
3. Wait for all-clear announcement
4. Generate new identity if advised

## Security Checklist

### Pre-Deployment

- [ ] Complete internal security review
- [ ] External audit by reputable firm
- [ ] Fuzz testing with >10k iterations
- [ ] Integration testing on testnet
- [ ] Proper trusted setup ceremony
- [ ] Deploy circom-generated verifier
- [ ] Set up guardian multisig with diverse members
- [ ] Configure oracle with appropriate parameters
- [ ] Document all deployment addresses
- [ ] Prepare emergency response procedures

### Post-Deployment

- [ ] Monitor all transactions
- [ ] Set up alerting for anomalies
- [ ] Regular guardian key rotations
- [ ] Periodic security reviews
- [ ] Community bug bounty program
- [ ] Regular dependency updates
- [ ] Maintain incident response plan
- [ ] Conduct emergency drills

## References

- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [ZK Security Considerations](https://www.zkdocs.com/)
- [Groth16 Security Analysis](https://eprint.iacr.org/2016/260.pdf)
- [Ethereum Security Guide](https://ethereum.org/en/developers/docs/security/)

## Contact

For security-related inquiries:
- **Email**: security@echoveil.io
- **Discord**: [To be created]
- **Twitter**: @EchoVeil

---

**Last Updated**: December 2024  
**Version**: 0.1.0

Security considerations documented
