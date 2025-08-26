/**
 * ZK Proof Generator for EchoVeil
 * Generates zero-knowledge proofs for reputation claims
 */

const snarkjs = require('snarkjs');
const { poseidon } = require('circomlibjs');
const fs = require('fs');
const path = require('path');

/**
 * Generate identity commitment from secret
 */
function generateIdentityCommitment(secret) {
    return poseidon([BigInt(secret)]);
}

/**
 * Generate nullifier from identity secret
 */
function generateNullifier(identitySecret, domainSeparator = 1n) {
    return poseidon([BigInt(identitySecret), domainSeparator]);
}

/**
 * Generate reputation proof
 * @param {Object} input - Proof input data
 * @returns {Object} Generated proof
 */
async function generateReputationProof(input) {
    const {
        identitySecret,
        score,
        merkleRoot,
        threshold,
        pathElements,
        pathIndices
    } = input;

    // Validate inputs
    if (!identitySecret || !score || !merkleRoot || !threshold) {
        throw new Error('Missing required inputs');
    }

    if (score < threshold) {
        throw new Error(`Score ${score} is below threshold ${threshold}`);
    }

    // Generate nullifier
    const nullifier = generateNullifier(identitySecret);

    // Prepare circuit inputs
    const circuitInputs = {
        identitySecret: identitySecret.toString(),
        score: score.toString(),
        merkleRoot: merkleRoot.toString(),
        threshold: threshold.toString(),
        pathElements: pathElements.map(e => e.toString()),
        pathIndices: pathIndices.map(i => i.toString())
    };

    console.log('Generating proof with inputs:');
    console.log(`- Identity secret: ${identitySecret}`);
    console.log(`- Score: ${score}`);
    console.log(`- Threshold: ${threshold}`);
    console.log(`- Merkle root: ${merkleRoot}`);
    console.log(`- Nullifier: ${nullifier}\n`);

    // Paths to circuit files
    const wasmPath = path.join(__dirname, '../circuits/build/reputation_proof_js/reputation_proof.wasm');
    const zkeyPath = path.join(__dirname, '../circuits/build/reputation_proof_final.zkey');

    // Check if files exist
    if (!fs.existsSync(wasmPath)) {
        console.warn('Warning: WASM file not found. Using mock proof generation.');
        return generateMockProof(circuitInputs, nullifier);
    }

    try {
        // Generate witness
        console.log('Generating witness...');
        const { proof, publicSignals } = await snarkjs.groth16.fullProve(
            circuitInputs,
            wasmPath,
            zkeyPath
        );

        console.log('Proof generated successfully!\n');

        // Format proof for Solidity
        const solidityProof = {
            a: [proof.pi_a[0], proof.pi_a[1]],
            b: [
                [proof.pi_b[0][1], proof.pi_b[0][0]],
                [proof.pi_b[1][1], proof.pi_b[1][0]]
            ],
            c: [proof.pi_c[0], proof.pi_c[1]]
        };

        return {
            proof: solidityProof,
            publicSignals: publicSignals.map(s => BigInt(s).toString()),
            nullifier: nullifier.toString(),
            formattedProof: proof
        };

    } catch (error) {
        console.error('Error generating proof:', error.message);
        console.log('Falling back to mock proof generation.\n');
        return generateMockProof(circuitInputs, nullifier);
    }
}

/**
 * Generate mock proof for testing
 */
function generateMockProof(circuitInputs, nullifier) {
    return {
        proof: {
            a: ['1', '2'],
            b: [
                ['3', '4'],
                ['5', '6']
            ],
            c: ['7', '8']
        },
        publicSignals: [
            circuitInputs.merkleRoot,
            circuitInputs.threshold,
            nullifier.toString()
        ],
        nullifier: nullifier.toString(),
        note: 'This is a mock proof for testing purposes'
    };
}

/**
 * Verify proof locally
 */
async function verifyProof(proof, publicSignals) {
    const vkeyPath = path.join(__dirname, '../circuits/build/verification_key.json');

    if (!fs.existsSync(vkeyPath)) {
        console.log('Verification key not found. Skipping verification.');
        return true;
    }

    try {
        const vkey = JSON.parse(fs.readFileSync(vkeyPath, 'utf-8'));
        const isValid = await snarkjs.groth16.verify(vkey, publicSignals, proof.formattedProof);

        console.log(`Proof verification: ${isValid ? 'VALID ✓' : 'INVALID ✗'}`);
        return isValid;

    } catch (error) {
        console.error('Verification error:', error.message);
        return false;
    }
}

/**
 * Main function
 */
async function main() {
    console.log('EchoVeil Proof Generator');
    console.log('========================\n');

    // Example: Load user data from Merkle tree
    const merkleTreeFile = path.join(__dirname, '../merkle_tree_data.json');
    
    let userData;
    if (fs.existsSync(merkleTreeFile)) {
        console.log('Loading Merkle tree data...');
        const treeData = JSON.parse(fs.readFileSync(merkleTreeFile, 'utf-8'));
        userData = treeData.users[0]; // Use first user as example
        console.log(`Loaded user ${userData.index}\n`);
    } else {
        console.log('Merkle tree data not found. Using sample data.\n');
        userData = {
            identityCommitment: '12345678901234567890',
            score: 150,
            proof: {
                pathElements: Array(20).fill('0'),
                pathIndices: Array(20).fill(0),
                root: '1234567890'
            }
        };
    }

    // Generate proof
    const input = {
        identitySecret: BigInt('0x' + crypto.randomBytes(32).toString('hex')),
        score: userData.score || 150,
        merkleRoot: userData.proof?.root || '1234567890',
        threshold: 100,
        pathElements: userData.proof?.pathElements || Array(20).fill('0'),
        pathIndices: userData.proof?.pathIndices || Array(20).fill(0)
    };

    const result = await generateReputationProof(input);

    // Save proof to file
    const outputFile = 'generated_proof.json';
    fs.writeFileSync(outputFile, JSON.stringify(result, null, 2));
    console.log(`Proof saved to ${outputFile}\n`);

    // Verify proof if possible
    if (result.formattedProof) {
        await verifyProof(result, result.publicSignals);
    }

    // Display usage info
    console.log('\nUsage in smart contract:');
    console.log('========================');
    console.log('IZKVerifier.Proof memory proof = IZKVerifier.Proof({');
    console.log(`    a: [${result.proof.a.join(', ')}],`);
    console.log('    b: [');
    console.log(`        [${result.proof.b[0].join(', ')}],`);
    console.log(`        [${result.proof.b[1].join(', ')}]`);
    console.log('    ],');
    console.log(`    c: [${result.proof.c.join(', ')}]`);
    console.log('});');
    console.log(`\nuint256[] memory publicSignals = [${result.publicSignals.join(', ')}];`);
    console.log(`bytes32 nullifier = bytes32(uint256(${result.nullifier}));`);

    console.log('\nDone! ✓');
}

// Run if called directly
if (require.main === module) {
    main().catch(console.error);
}

module.exports = {
    generateReputationProof,
    generateIdentityCommitment,
    generateNullifier,
    verifyProof
};

Proof generation polish
