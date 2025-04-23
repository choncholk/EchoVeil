# EchoVeil API Reference

## Smart Contract Interfaces

### IdentityRegistry

#### registerIdentity

```solidity
function registerIdentity(bytes32 identityHash, bytes calldata zkProof) external
```

Register a new identity commitment with zero-knowledge proof.

**Parameters**:
- `identityHash`: Commitment hash of the user's identity
- `zkProof`: Zero-knowledge proof data

**Events**: `IdentityRegistered`

**Requirements**:
- Identity hash must be non-zero
- User must not have existing identity
- Proof must be non-empty

---

#### consumeNullifier

```solidity
function consumeNullifier(bytes32 nullifier) external
```

Mark a nullifier as consumed (one-time use).

**Parameters**:
- `nullifier`: The nullifier hash to consume

**Events**: `NullifierConsumed`

**Requirements**:
- Nullifier must not be already used
- Caller must have registered identity

---

#### isRegistered

```solidity
function isRegistered(address user) external view returns (bool)
```

Check if an address has a registered identity.

**Parameters**:
- `user`: Address to check

**Returns**: `true` if identity is registered

---

### ReputationCore

#### updateRoot

```solidity
function updateRoot(bytes32 newRoot) external
```

Update the current Merkle root (guardian or oracle only).

**Parameters**:
- `newRoot`: New Merkle root hash

**Events**: `RootUpdated`

**Requirements**:
- Caller must be oracle or guardian
- New root must be non-zero and different from current

---

#### getCurrentRoot

```solidity
function getCurrentRoot() external view returns (bytes32)
```

Get the current Merkle root.

**Returns**: Current Merkle root hash

---

#### getCurrentEpoch

```solidity
function getCurrentEpoch() external view returns (uint256)
```

Get the current epoch number.

**Returns**: Current epoch

---

#### advanceEpoch

```solidity
function advanceEpoch() external
```

Advance to the next epoch (guardian only).

**Events**: `EpochTransitioned`

**Requirements**:
- Caller must be guardian
- Minimum epoch duration must have elapsed

---

### ZKVerifier

#### verifyReputationProof

```solidity
function verifyReputationProof(
    Proof calldata proof,
    uint256[] calldata publicSignals
) external view returns (bool)
```

Verify a zero-knowledge reputation proof.

**Parameters**:
- `proof`: Groth16 proof structure
- `publicSignals`: Public inputs to the circuit

**Returns**: `true` if proof is valid

---

#### verifyMerkleInclusion

```solidity
function verifyMerkleInclusion(
    Proof calldata proof,
    bytes32 root,
    bytes32 nullifier,
    bytes32 commitment
) external view returns (bool)
```

Verify Merkle tree inclusion proof.

**Parameters**:
- `proof`: Zero-knowledge proof
- `root`: Merkle root
- `nullifier`: Nullifier hash
- `commitment`: User commitment

**Returns**: `true` if proof is valid

---

#### verifyEligibilityProof

```solidity
function verifyEligibilityProof(
    Proof calldata proof,
    bytes32 root,
    uint256 threshold,
    bytes32 nullifier
) external view returns (bool)
```

Verify eligibility proof with score threshold.

**Parameters**:
- `proof`: Zero-knowledge proof
- `root`: Merkle root
- `threshold`: Minimum reputation score
- `nullifier`: Nullifier hash

**Returns**: `true` if proof is valid and score ≥ threshold

---

### ProofGateway

#### verifyEligibility

```solidity
function verifyEligibility(
    IZKVerifier.Proof calldata proof,
    EligibilityRequirement calldata requirement,
    bytes32 nullifier
) external returns (VerificationResult memory)
```

Verify eligibility with comprehensive checks.

**Parameters**:
- `proof`: Zero-knowledge proof
- `requirement`: Eligibility requirements structure
- `nullifier`: User nullifier

**Returns**: Verification result structure

**Events**: `EligibilityVerified`

**Requirements**:
- Nullifier must not be used
- Epoch must be valid
- Merkle root must be valid

---

#### batchVerifyEligibility

```solidity
function batchVerifyEligibility(
    IZKVerifier.Proof[] calldata proofs,
    EligibilityRequirement[] calldata requirements,
    bytes32[] calldata nullifiers
) external returns (VerificationResult[] memory results)
```

Batch verify multiple proofs in a single transaction.

**Parameters**:
- `proofs`: Array of zero-knowledge proofs
- `requirements`: Array of eligibility requirements
- `nullifiers`: Array of nullifiers

**Returns**: Array of verification results

**Requirements**:
- Arrays must have equal length

---

#### registerDApp

```solidity
function registerDApp(string calldata metadata) external
```

Register a dApp for verification services.

**Parameters**:
- `metadata`: IPFS hash or metadata URI

**Events**: `DAppRegistered`

**Requirements**:
- dApp must not be already registered
- Metadata must be non-empty

---

### ScoreOracle

#### proposeRootUpdate

```solidity
function proposeRootUpdate(bytes32 newRoot) external
```

Propose a new Merkle root update (operator only).

**Parameters**:
- `newRoot`: New Merkle root to commit

**Events**: `RootUpdateProposed`

**Requirements**:
- Caller must be oracle operator
- Oracle must not be paused
- Update cooldown must have elapsed
- No pending update exists

---

#### executeRootUpdate

```solidity
function executeRootUpdate() external
```

Execute a pending root update after timelock (operator only).

**Events**: `RootUpdateExecuted`

**Requirements**:
- Caller must be oracle operator
- Oracle must not be paused
- Pending update must exist
- Timelock delay must have elapsed

---

#### emergencyUpdateRoot

```solidity
function emergencyUpdateRoot(bytes32 newRoot) external
```

Emergency root update bypassing timelock (guardian only).

**Parameters**:
- `newRoot`: New Merkle root

**Events**: `RootUpdateExecuted`

**Requirements**:
- Caller must be guardian

---

### GuardianMultisig

#### submitTransaction

```solidity
function submitTransaction(
    address target,
    uint256 value,
    bytes calldata data
) external returns (uint256 txId)
```

Submit a new transaction for guardian approval.

**Parameters**:
- `target`: Target contract address
- `value`: ETH value to send
- `data`: Transaction data

**Returns**: Transaction ID

**Events**: `TransactionSubmitted`

**Requirements**:
- Caller must be guardian

---

#### confirmTransaction

```solidity
function confirmTransaction(uint256 txId) external
```

Confirm a pending transaction.

**Parameters**:
- `txId`: Transaction ID

**Events**: `TransactionConfirmed`

**Requirements**:
- Caller must be guardian
- Transaction must exist and not be executed
- Guardian must not have already confirmed

---

#### executeTransaction

```solidity
function executeTransaction(uint256 txId) external
```

Execute a transaction with sufficient confirmations.

**Parameters**:
- `txId`: Transaction ID

**Events**: `TransactionExecuted`

**Requirements**:
- Caller must be guardian
- Transaction must exist and not be executed
- Must have required confirmations

---

## Data Structures

### Proof (Groth16)

```solidity
struct Proof {
    uint256[2] a;
    uint256[2][2] b;
    uint256[2] c;
}
```

### EligibilityRequirement

```solidity
struct EligibilityRequirement {
    bytes32 merkleRoot;
    uint256 minScore;
    uint256 maxScore;
    uint256 epoch;
    bool requireSybilResistance;
}
```

### VerificationResult

```solidity
struct VerificationResult {
    bool success;
    bytes32 nullifier;
    uint256 timestamp;
    address verifier;
}
```

## Events

### IdentityRegistered

```solidity
event IdentityRegistered(
    address indexed user,
    bytes32 indexed identityHash,
    uint256 timestamp
)
```

### NullifierConsumed

```solidity
event NullifierConsumed(
    bytes32 indexed nullifier,
    address indexed user
)
```

### RootUpdated

```solidity
event RootUpdated(
    uint256 indexed epoch,
    bytes32 indexed newRoot,
    bytes32 previousRoot,
    uint256 timestamp
)
```

### EpochTransitioned

```solidity
event EpochTransitioned(
    uint256 oldEpoch,
    uint256 newEpoch
)
```

### EligibilityVerified

```solidity
event EligibilityVerified(
    address indexed user,
    bool success,
    bytes32 indexed nullifier,
    uint256 timestamp
)
```

### DAppRegistered

```solidity
event DAppRegistered(
    address indexed dapp,
    uint256 timestamp
)
```

### RootUpdateProposed

```solidity
event RootUpdateProposed(
    bytes32 indexed newRoot,
    uint256 timestamp,
    address operator
)
```

### TransactionSubmitted

```solidity
event TransactionSubmitted(
    uint256 indexed txId,
    address indexed submitter,
    address target,
    uint256 value,
    bytes data
)
```

## Error Messages

| Error | Description |
|-------|-------------|
| `Invalid verifier address` | ZK verifier address is zero |
| `Invalid identity hash` | Identity hash is zero |
| `Identity already registered` | User already has registered identity |
| `Invalid proof` | Proof data is empty or invalid |
| `Nullifier already used` | Nullifier has been consumed |
| `Identity not registered` | User has no registered identity |
| `Only guardian` | Caller is not guardian |
| `Only oracle or guardian` | Caller is neither oracle nor guardian |
| `Invalid root` | Root is zero or invalid |
| `Epoch duration not elapsed` | Cannot advance epoch yet |
| `Invalid epoch` | Epoch number is invalid |
| `Invalid Merkle root` | Root is not valid for current epoch |
| `Oracle is paused` | Oracle operations are paused |
| `Update cooldown not elapsed` | Must wait before next update |
| `Pending update exists` | Previous update not yet executed |
| `Timelock not elapsed` | Must wait for timelock delay |
| `Not a guardian` | Caller is not a guardian |
| `Transaction does not exist` | Invalid transaction ID |
| `Transaction already executed` | Transaction was already executed |
| `Insufficient confirmations` | Not enough guardian confirmations |

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `MIN_PROOF_AGE` | 1 hour | Minimum proof validity period |
| `EPOCH_DURATION` | 1 day | Minimum epoch duration |
| `UPDATE_COOLDOWN` | 1 day | Oracle update cooldown |
| `TIMELOCK_DELAY` | 1 hour | Oracle timelock delay |
| `CIRCUIT_VERSION` | 1 | Current circuit version |
| `MAX_HISTORICAL_EPOCHS` | 100 | Maximum stored historical epochs |

API enhancements
