/**
 * Merkle Tree Generator for EchoVeil
 * Generates reputation Merkle tree from user scores
 */

const { poseidon } = require('circomlibjs');
const fs = require('fs');

class MerkleTree {
    constructor(levels) {
        this.levels = levels;
        this.maxLeaves = 2 ** levels;
        this.leaves = [];
        this.tree = [];
    }

    /**
     * Add a leaf to the tree
     * @param {string} identityCommitment - User identity commitment
     * @param {number} score - User reputation score
     */
    addLeaf(identityCommitment, score) {
        if (this.leaves.length >= this.maxLeaves) {
            throw new Error('Tree is full');
        }

        const leaf = poseidon([identityCommitment, score]);
        this.leaves.push(leaf);
    }

    /**
     * Build the Merkle tree
     */
    build() {
        if (this.leaves.length === 0) {
            throw new Error('No leaves to build tree');
        }

        // Pad with zeros to fill tree
        const paddedLeaves = [...this.leaves];
        while (paddedLeaves.length < this.maxLeaves) {
            paddedLeaves.push(0n);
        }

        this.tree = [paddedLeaves];

        // Build tree level by level
        for (let level = 0; level < this.levels; level++) {
            const currentLevel = this.tree[level];
            const nextLevel = [];

            for (let i = 0; i < currentLevel.length; i += 2) {
                const left = currentLevel[i];
                const right = currentLevel[i + 1];
                const parent = poseidon([left, right]);
                nextLevel.push(parent);
            }

            this.tree.push(nextLevel);
        }
    }

    /**
     * Get Merkle root
     * @returns {BigInt} Merkle root
     */
    getRoot() {
        if (this.tree.length === 0) {
            throw new Error('Tree not built');
        }
        return this.tree[this.tree.length - 1][0];
    }

    /**
     * Get Merkle proof for a leaf
     * @param {number} leafIndex - Index of the leaf
     * @returns {Object} Merkle proof
     */
    getProof(leafIndex) {
        if (leafIndex >= this.leaves.length) {
            throw new Error('Invalid leaf index');
        }

        const pathElements = [];
        const pathIndices = [];
        let currentIndex = leafIndex;

        for (let level = 0; level < this.levels; level++) {
            const isRightNode = currentIndex % 2 === 1;
            const siblingIndex = isRightNode ? currentIndex - 1 : currentIndex + 1;
            
            pathElements.push(this.tree[level][siblingIndex]);
            pathIndices.push(isRightNode ? 1 : 0);
            
            currentIndex = Math.floor(currentIndex / 2);
        }

        return {
            pathElements: pathElements.map(e => e.toString()),
            pathIndices,
            root: this.getRoot().toString(),
            leaf: this.leaves[leafIndex].toString()
        };
    }

    /**
     * Export tree to JSON
     * @returns {Object} Tree data
     */
    toJSON() {
        return {
            levels: this.levels,
            leafCount: this.leaves.length,
            root: this.getRoot().toString(),
            leaves: this.leaves.map(l => l.toString())
        };
    }
}

/**
 * Generate sample reputation data
 */
function generateSampleData(count) {
    const users = [];
    
    for (let i = 0; i < count; i++) {
        users.push({
            identityCommitment: BigInt(`0x${crypto.randomBytes(32).toString('hex')}`),
            score: Math.floor(Math.random() * 1000)
        });
    }
    
    return users;
}

/**
 * Main function
 */
async function main() {
    console.log('EchoVeil Merkle Tree Generator');
    console.log('===============================\n');

    // Configuration
    const TREE_LEVELS = 20; // Support up to 2^20 = 1M users
    const USER_COUNT = 100;

    // Generate sample data
    console.log(`Generating ${USER_COUNT} sample users...`);
    const users = generateSampleData(USER_COUNT);

    // Build tree
    console.log('Building Merkle tree...');
    const tree = new MerkleTree(TREE_LEVELS);

    for (const user of users) {
        tree.addLeaf(user.identityCommitment, user.score);
    }

    tree.build();

    console.log(`Tree root: ${tree.getRoot()}`);
    console.log(`Tree depth: ${TREE_LEVELS}`);
    console.log(`Leaf count: ${users.length}\n`);

    // Generate sample proof
    console.log('Generating sample proof for user 0...');
    const proof = tree.getProof(0);
    console.log(`Leaf: ${proof.leaf}`);
    console.log(`Root: ${proof.root}`);
    console.log(`Path length: ${proof.pathElements.length}\n`);

    // Export data
    const exportData = {
        tree: tree.toJSON(),
        users: users.map((u, i) => ({
            index: i,
            identityCommitment: u.identityCommitment.toString(),
            score: u.score,
            proof: tree.getProof(i)
        })),
        sampleProof: proof
    };

    const outputFile = 'merkle_tree_data.json';
    fs.writeFileSync(outputFile, JSON.stringify(exportData, null, 2));
    console.log(`Data exported to ${outputFile}`);

    // Generate on-chain update data
    const updateData = {
        merkleRoot: `0x${tree.getRoot().toString(16).padStart(64, '0')}`,
        epoch: 0,
        timestamp: Date.now(),
        leafCount: users.length
    };

    fs.writeFileSync('merkle_root_update.json', JSON.stringify(updateData, null, 2));
    console.log('Update data exported to merkle_root_update.json');

    console.log('\nDone! ✓');
}

// Run if called directly
if (require.main === module) {
    main().catch(console.error);
}

module.exports = { MerkleTree };

Merkle tree script polish
