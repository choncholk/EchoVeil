pragma circom 2.1.6;

include "circomlib/circuits/poseidon.circom";
include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/mux1.circom";

/**
 * @title ReputationProofCircuit
 * @notice Zero-knowledge circuit for proving reputation score eligibility
 * @dev Proves user has score >= threshold without revealing exact score
 */
template ReputationProofCircuit(levels) {
    // Public inputs
    signal input merkleRoot;
    signal input threshold;
    signal input nullifier;
    
    // Private inputs
    signal input identitySecret;
    signal input score;
    signal input pathIndices[levels];
    signal input pathElements[levels];
    
    // Output signals
    signal output isValid;
    
    // 1. Compute identity commitment
    component identityHasher = Poseidon(1);
    identityHasher.inputs[0] <== identitySecret;
    signal identityCommitment;
    identityCommitment <== identityHasher.out;
    
    // 2. Compute nullifier from identity secret
    component nullifierHasher = Poseidon(2);
    nullifierHasher.inputs[0] <== identitySecret;
    nullifierHasher.inputs[1] <== 1; // Domain separator
    nullifier === nullifierHasher.out;
    
    // 3. Verify score >= threshold
    component scoreCheck = GreaterEqThan(64);
    scoreCheck.in[0] <== score;
    scoreCheck.in[1] <== threshold;
    scoreCheck.out === 1;
    
    // 4. Create leaf hash (identity + score)
    component leafHasher = Poseidon(2);
    leafHasher.inputs[0] <== identityCommitment;
    leafHasher.inputs[1] <== score;
    
    // 5. Verify Merkle proof
    component merkleProof[levels];
    signal currentHash[levels + 1];
    currentHash[0] <== leafHasher.out;
    
    for (var i = 0; i < levels; i++) {
        merkleProof[i] = Poseidon(2);
        
        // Select left or right based on path index
        component mux = Mux1();
        mux.c[0] <== currentHash[i];
        mux.c[1] <== pathElements[i];
        mux.s <== pathIndices[i];
        
        merkleProof[i].inputs[0] <== mux.out;
        
        mux.c[0] <== pathElements[i];
        mux.c[1] <== currentHash[i];
        mux.s <== pathIndices[i];
        
        merkleProof[i].inputs[1] <== mux.out;
        
        currentHash[i + 1] <== merkleProof[i].out;
    }
    
    // 6. Verify computed root matches public root
    merkleRoot === currentHash[levels];
    
    // Output success
    isValid <== 1;
}

/**
 * @title MerkleInclusionCircuit
 * @notice Simpler circuit for proving Merkle tree inclusion
 */
template MerkleInclusionCircuit(levels) {
    signal input merkleRoot;
    signal input nullifier;
    signal input commitment;
    
    // Private inputs
    signal input identitySecret;
    signal input pathIndices[levels];
    signal input pathElements[levels];
    
    // Verify commitment
    component commitmentHasher = Poseidon(1);
    commitmentHasher.inputs[0] <== identitySecret;
    commitment === commitmentHasher.out;
    
    // Verify nullifier
    component nullifierHasher = Poseidon(2);
    nullifierHasher.inputs[0] <== identitySecret;
    nullifierHasher.inputs[1] <== 1;
    nullifier === nullifierHasher.out;
    
    // Merkle proof verification
    component merkleHashers[levels];
    signal hashes[levels + 1];
    hashes[0] <== commitment;
    
    for (var i = 0; i < levels; i++) {
        merkleHashers[i] = Poseidon(2);
        
        var left = hashes[i];
        var right = pathElements[i];
        
        if (pathIndices[i] == 1) {
            left = pathElements[i];
            right = hashes[i];
        }
        
        merkleHashers[i].inputs[0] <== left;
        merkleHashers[i].inputs[1] <== right;
        hashes[i + 1] <== merkleHashers[i].out;
    }
    
    merkleRoot === hashes[levels];
}

// Main component instantiation
component main {public [merkleRoot, threshold, nullifier]} = ReputationProofCircuit(20);

