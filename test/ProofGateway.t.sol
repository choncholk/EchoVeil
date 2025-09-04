// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/core/ProofGateway.sol";
import "../contracts/core/ZKVerifier.sol";
import "../contracts/core/ReputationCore.sol";
import "../contracts/core/IdentityRegistry.sol";

contract ProofGatewayTest is Test {
    ProofGateway public proofGateway;
    ZKVerifier public zkVerifier;
    ReputationCore public reputationCore;
    IdentityRegistry public identityRegistry;

    address public guardian;
    address public oracle;
    address public dapp;
    address public user;

    bytes32 public constant MERKLE_ROOT = keccak256("merkle_root");
    bytes32 public constant NULLIFIER = keccak256("nullifier");

    IZKVerifier.Proof public validProof;
    IProofGateway.EligibilityRequirement public requirement;

    function setUp() public {
        guardian = address(0x1111);
        oracle = address(0x2222);
        dapp = address(0x3333);
        user = address(0x4444);

        // Deploy contracts
        bytes32 vkHash = keccak256("vk");
        zkVerifier = new ZKVerifier(vkHash, false);
        identityRegistry = new IdentityRegistry(address(zkVerifier));
        reputationCore = new ReputationCore(guardian, oracle, MERKLE_ROOT);
        proofGateway = new ProofGateway(
            address(zkVerifier),
            address(reputationCore),
            address(identityRegistry)
        );

        // Setup valid proof
        validProof = IZKVerifier.Proof({
            a: [uint256(1), uint256(2)],
            b: [[uint256(3), uint256(4)], [uint256(5), uint256(6)]],
            c: [uint256(7), uint256(8)]
        });

        // Setup requirement
        requirement = IProofGateway.EligibilityRequirement({
            merkleRoot: MERKLE_ROOT,
            minScore: 100,
            maxScore: type(uint256).max,
            epoch: 0,
            requireSybilResistance: false
        });
    }

    function testVerifyEligibility() public {
        vm.prank(user);
        IProofGateway.VerificationResult memory result = 
            proofGateway.verifyEligibility(validProof, requirement, NULLIFIER);

        assertTrue(result.success);
        assertEq(result.nullifier, NULLIFIER);
        assertEq(result.verifier, user);
        assertTrue(proofGateway.isNullifierUsed(NULLIFIER));
    }

    function testCannotReuseNullifier() public {
        vm.startPrank(user);
        proofGateway.verifyEligibility(validProof, requirement, NULLIFIER);

        vm.expectRevert("Nullifier already used");
        proofGateway.verifyEligibility(validProof, requirement, NULLIFIER);
        vm.stopPrank();
    }

    function testCannotVerifyInvalidEpoch() public {
        requirement.epoch = 999;

        vm.prank(user);
        vm.expectRevert("Invalid epoch");
        proofGateway.verifyEligibility(validProof, requirement, NULLIFIER);
    }

    function testCannotVerifyInvalidRoot() public {
        requirement.merkleRoot = keccak256("invalid_root");

        vm.prank(user);
        vm.expectRevert("Invalid Merkle root");
        proofGateway.verifyEligibility(validProof, requirement, NULLIFIER);
    }

    function testRegisterDApp() public {
        string memory metadata = "ipfs://QmTest123";

        vm.prank(dapp);
        proofGateway.registerDApp(metadata);

        assertTrue(proofGateway.isDAppRegistered(dapp));
        assertEq(proofGateway.getDAppMetadata(dapp), metadata);
    }

    function testCannotRegisterDAppTwice() public {
        string memory metadata = "ipfs://QmTest123";

        vm.startPrank(dapp);
        proofGateway.registerDApp(metadata);

        vm.expectRevert("dApp already registered");
        proofGateway.registerDApp(metadata);
        vm.stopPrank();
    }

    function testGetVerificationResult() public {
        vm.prank(user);
        proofGateway.verifyEligibility(validProof, requirement, NULLIFIER);

        IProofGateway.VerificationResult memory storedResult = 
            proofGateway.getVerificationResult(user, NULLIFIER);

        assertTrue(storedResult.success);
        assertEq(storedResult.nullifier, NULLIFIER);
        assertEq(storedResult.verifier, user);
    }

    function testBatchVerifyEligibility() public {
        IZKVerifier.Proof[] memory proofs = new IZKVerifier.Proof[](2);
        IProofGateway.EligibilityRequirement[] memory requirements = 
            new IProofGateway.EligibilityRequirement[](2);
        bytes32[] memory nullifiers = new bytes32[](2);

        proofs[0] = validProof;
        proofs[1] = validProof;
        requirements[0] = requirement;
        requirements[1] = requirement;
        nullifiers[0] = keccak256("nullifier1");
        nullifiers[1] = keccak256("nullifier2");

        vm.prank(user);
        IProofGateway.VerificationResult[] memory results = 
            proofGateway.batchVerifyEligibility(proofs, requirements, nullifiers);

        assertEq(results.length, 2);
        assertTrue(results[0].success);
        assertTrue(results[1].success);
        assertTrue(proofGateway.isNullifierUsed(nullifiers[0]));
        assertTrue(proofGateway.isNullifierUsed(nullifiers[1]));
    }

    function testBatchVerifyArrayLengthMismatch() public {
        IZKVerifier.Proof[] memory proofs = new IZKVerifier.Proof[](2);
        IProofGateway.EligibilityRequirement[] memory requirements = 
            new IProofGateway.EligibilityRequirement[](1);
        bytes32[] memory nullifiers = new bytes32[](2);

        vm.prank(user);
        vm.expectRevert("Array length mismatch");
        proofGateway.batchVerifyEligibility(proofs, requirements, nullifiers);
    }

    function testVerifyWithSybilResistance() public {
        requirement.requireSybilResistance = true;

        vm.prank(user);
        IProofGateway.VerificationResult memory result = 
            proofGateway.verifyEligibility(validProof, requirement, NULLIFIER);

        assertTrue(result.success);
    }

    function testMultipleUsersCanVerify() public {
        address user2 = address(0x5555);
        bytes32 nullifier2 = keccak256("nullifier2");

        vm.prank(user);
        IProofGateway.VerificationResult memory result1 = 
            proofGateway.verifyEligibility(validProof, requirement, NULLIFIER);

        vm.prank(user2);
        IProofGateway.VerificationResult memory result2 = 
            proofGateway.verifyEligibility(validProof, requirement, nullifier2);

        assertTrue(result1.success);
        assertTrue(result2.success);
        assertEq(result1.verifier, user);
        assertEq(result2.verifier, user2);
    }
}

ProofGateway test polish
