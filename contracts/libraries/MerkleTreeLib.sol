// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MerkleTreeLib
 * @notice Library for Merkle tree verification and utilities
 * @dev Provides helpers for working with Merkle proofs
 */
library MerkleTreeLib {
    /**
     * @notice Verify a Merkle proof
     * @param leaf Leaf hash to verify
     * @param root Expected Merkle root
     * @param proof Array of sibling hashes
     * @param index Leaf index in the tree
     * @return bool True if proof is valid
     */
    function verify(
        bytes32 leaf,
        bytes32 root,
        bytes32[] memory proof,
        uint256 index
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (index % 2 == 0) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }

            index = index / 2;
        }

        return computedHash == root;
    }

    /**
     * @notice Verify a Merkle proof with path indices
     * @param leaf Leaf hash to verify
     * @param root Expected Merkle root
     * @param proof Array of sibling hashes
     * @param pathIndices Array indicating left (0) or right (1)
     * @return bool True if proof is valid
     */
    function verifyWithIndices(
        bytes32 leaf,
        bytes32 root,
        bytes32[] memory proof,
        uint256[] memory pathIndices
    ) internal pure returns (bool) {
        require(proof.length == pathIndices.length, "Length mismatch");

        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (pathIndices[i] == 0) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        return computedHash == root;
    }

    /**
     * @notice Hash two nodes together
     * @param left Left node hash
     * @param right Right node hash
     * @return bytes32 Parent hash
     */
    function hashPair(bytes32 left, bytes32 right) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(left, right));
    }

    /**
     * @notice Calculate tree depth from leaf count
     * @param leafCount Number of leaves
     * @return uint256 Tree depth
     */
    function calculateDepth(uint256 leafCount) internal pure returns (uint256) {
        if (leafCount == 0) return 0;
        
        uint256 depth = 0;
        uint256 n = leafCount - 1;
        
        while (n > 0) {
            depth++;
            n = n >> 1;
        }
        
        return depth;
    }

    /**
     * @notice Get the next power of 2
     * @param n Input number
     * @return uint256 Next power of 2
     */
    function nextPowerOf2(uint256 n) internal pure returns (uint256) {
        if (n == 0) return 1;
        
        n--;
        n |= n >> 1;
        n |= n >> 2;
        n |= n >> 4;
        n |= n >> 8;
        n |= n >> 16;
        n |= n >> 32;
        n |= n >> 64;
        n |= n >> 128;
        
        return n + 1;
    }

    /**
     * @notice Check if number is power of 2
     * @param n Input number
     * @return bool True if power of 2
     */
    function isPowerOf2(uint256 n) internal pure returns (bool) {
        return n > 0 && (n & (n - 1)) == 0;
    }

    /**
     * @notice Build root from leaf array (naive implementation)
     * @param leaves Array of leaf hashes
     * @return bytes32 Merkle root
     */
    function buildRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        require(leaves.length > 0, "Empty tree");

        uint256 n = leaves.length;
        uint256 offset = 0;

        while (n > 1) {
            for (uint256 i = 0; i < n / 2; i++) {
                leaves[offset + i] = hashPair(
                    leaves[offset + i * 2],
                    leaves[offset + i * 2 + 1]
                );
            }

            if (n % 2 == 1) {
                leaves[offset + n / 2] = leaves[offset + n - 1];
                n = n / 2 + 1;
            } else {
                n = n / 2;
            }

            offset += n;
        }

        return leaves[0];
    }

    /**
     * @notice Multi-proof verification (verify multiple leaves at once)
     * @param leaves Array of leaf hashes
     * @param root Expected Merkle root
     * @param proofs Array of proofs for each leaf
     * @param indices Array of leaf indices
     * @return bool True if all proofs are valid
     */
    function verifyMulti(
        bytes32[] memory leaves,
        bytes32 root,
        bytes32[][] memory proofs,
        uint256[] memory indices
    ) internal pure returns (bool) {
        require(
            leaves.length == proofs.length && leaves.length == indices.length,
            "Array length mismatch"
        );

        for (uint256 i = 0; i < leaves.length; i++) {
            if (!verify(leaves[i], root, proofs[i], indices[i])) {
                return false;
            }
        }

        return true;
    }
}

