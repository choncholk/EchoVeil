// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/core/ZKVerifier.sol";

contract ZKVerifierTest is Test {
    ZKVerifier public zkVerifier;
    bytes32 public constant VERIFYING_KEY_HASH = keccak256("test_key");

    IZKVerifier.Proof public validProof;
    uint256[] public publicSignals;

    function setUp() public {
        zkVerifier = new ZKVerifier(VERIFYING_KEY_HASH, false);

        // Setup a valid-looking proof
        validProof = IZKVerifier.Proof({
            a: [uint256(1), uint256(2)],
            b: [[uint256(3), uint256(4)], [uint256(5), uint256(6)]],
            c: [uint256(7), uint256(8)]
        });

        // Setup public signals
        publicSignals = new uint256[](3);
        publicSignals[0] = uint256(keccak256("merkle_root"));
        publicSignals[1] = 100; // threshold
        publicSignals[2] = uint256(keccak256("nullifier"));
    }

    function testVerifyingKeyHash() public {
        assertEq(zkVerifier.getVerifyingKeyHash(), VERIFYING_KEY_HASH);
    }

    function testCircuitVersion() public {
        assertEq(zkVerifier.getCircuitVersion(), 1);
    }

    function testVerifyReputationProof() public {
        bool result = zkVerifier.verifyReputationProof(validProof, publicSignals);
        assertTrue(result);
    }

    function testVerifyMerkleInclusion() public {
        bytes32 root = bytes32(uint256(123));
        bytes32 nullifier = bytes32(uint256(456));
        bytes32 commitment = bytes32(uint256(789));

        bool result = zkVerifier.verifyMerkleInclusion(
            validProof,
            root,
            nullifier,
            commitment
        );
        assertTrue(result);
    }

    function testVerifyEligibilityProof() public {
        bytes32 root = bytes32(uint256(123));
        uint256 threshold = 100;
        bytes32 nullifier = bytes32(uint256(456));

        bool result = zkVerifier.verifyEligibilityProof(
            validProof,
            root,
            threshold,
            nullifier
        );
        assertTrue(result);
    }

    function testCannotVerifyInvalidProofPointA() public {
        IZKVerifier.Proof memory invalidProof = IZKVerifier.Proof({
            a: [uint256(0), uint256(0)],
            b: [[uint256(3), uint256(4)], [uint256(5), uint256(6)]],
            c: [uint256(7), uint256(8)]
        });

        vm.expectRevert("Invalid proof point A");
        zkVerifier.verifyReputationProof(invalidProof, publicSignals);
    }

    function testCannotVerifyInvalidProofPointB() public {
        IZKVerifier.Proof memory invalidProof = IZKVerifier.Proof({
            a: [uint256(1), uint256(2)],
            b: [[uint256(0), uint256(0)], [uint256(0), uint256(0)]],
            c: [uint256(7), uint256(8)]
        });

        vm.expectRevert("Invalid proof point B");
        zkVerifier.verifyReputationProof(invalidProof, publicSignals);
    }

    function testCannotVerifyInvalidProofPointC() public {
        IZKVerifier.Proof memory invalidProof = IZKVerifier.Proof({
            a: [uint256(1), uint256(2)],
            b: [[uint256(3), uint256(4)], [uint256(5), uint256(6)]],
            c: [uint256(0), uint256(0)]
        });

        vm.expectRevert("Invalid proof point C");
        zkVerifier.verifyReputationProof(invalidProof, publicSignals);
    }

    function testCannotVerifyEmptyPublicSignals() public {
        uint256[] memory emptySignals = new uint256[](0);

        vm.expectRevert("No public signals");
        zkVerifier.verifyReputationProof(validProof, emptySignals);
    }

    function testCannotVerifyMerkleInclusionInvalidRoot() public {
        bytes32 invalidRoot = bytes32(0);
        bytes32 nullifier = bytes32(uint256(456));
        bytes32 commitment = bytes32(uint256(789));

        vm.expectRevert("Invalid root");
        zkVerifier.verifyMerkleInclusion(
            validProof,
            invalidRoot,
            nullifier,
            commitment
        );
    }

    function testCannotVerifyEligibilityInvalidThreshold() public {
        bytes32 root = bytes32(uint256(123));
        uint256 invalidThreshold = 0;
        bytes32 nullifier = bytes32(uint256(456));

        vm.expectRevert("Invalid threshold");
        zkVerifier.verifyEligibilityProof(
            validProof,
            root,
            invalidThreshold,
            nullifier
        );
    }

    function testStrictModeVerifier() public {
        ZKVerifier strictVerifier = new ZKVerifier(VERIFYING_KEY_HASH, true);
        
        bool result = strictVerifier.verifyReputationProof(validProof, publicSignals);
        assertTrue(result);
    }

    function testFuzzProofVerification(
        uint256 a0,
        uint256 a1,
        uint256 b00,
        uint256 b01,
        uint256 b10,
        uint256 b11,
        uint256 c0,
        uint256 c1
    ) public {
        vm.assume(a0 != 0 || a1 != 0);
        vm.assume(b00 != 0 || b01 != 0 || b10 != 0 || b11 != 0);
        vm.assume(c0 != 0 || c1 != 0);

        IZKVerifier.Proof memory fuzzProof = IZKVerifier.Proof({
            a: [a0, a1],
            b: [[b00, b01], [b10, b11]],
            c: [c0, c1]
        });

        bool result = zkVerifier.verifyReputationProof(fuzzProof, publicSignals);
        assertTrue(result);
    }
}

