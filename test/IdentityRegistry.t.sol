// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/core/IdentityRegistry.sol";

contract IdentityRegistryTest is Test {
    IdentityRegistry public identityRegistry;
    address public zkVerifier;
    address public user1;
    address public user2;

    bytes32 public constant IDENTITY_HASH_1 = keccak256("identity1");
    bytes32 public constant IDENTITY_HASH_2 = keccak256("identity2");
    bytes32 public constant NULLIFIER_1 = keccak256("nullifier1");
    bytes32 public constant NULLIFIER_2 = keccak256("nullifier2");

    function setUp() public {
        zkVerifier = address(0x1234);
        user1 = address(0x5678);
        user2 = address(0x9ABC);

        identityRegistry = new IdentityRegistry(zkVerifier);
    }

    function testRegisterIdentity() public {
        vm.prank(user1);
        identityRegistry.registerIdentity(
            IDENTITY_HASH_1,
            abi.encodePacked("proof_data")
        );

        assertTrue(identityRegistry.isRegistered(user1));
        assertEq(identityRegistry.getIdentityHash(user1), IDENTITY_HASH_1);
    }

    function testCannotRegisterTwice() public {
        vm.startPrank(user1);
        identityRegistry.registerIdentity(
            IDENTITY_HASH_1,
            abi.encodePacked("proof_data")
        );

        vm.expectRevert("Identity already registered");
        identityRegistry.registerIdentity(
            IDENTITY_HASH_2,
            abi.encodePacked("proof_data")
        );
        vm.stopPrank();
    }

    function testValidateNullifier() public {
        assertTrue(identityRegistry.validateNullifier(NULLIFIER_1));
        assertFalse(identityRegistry.isNullifierUsed(NULLIFIER_1));
    }

    function testConsumeNullifier() public {
        // Register identity first
        vm.prank(user1);
        identityRegistry.registerIdentity(
            IDENTITY_HASH_1,
            abi.encodePacked("proof_data")
        );

        // Consume nullifier
        vm.prank(user1);
        identityRegistry.consumeNullifier(NULLIFIER_1);

        assertFalse(identityRegistry.validateNullifier(NULLIFIER_1));
        assertTrue(identityRegistry.isNullifierUsed(NULLIFIER_1));
    }

    function testCannotConsumeNullifierTwice() public {
        vm.startPrank(user1);
        identityRegistry.registerIdentity(
            IDENTITY_HASH_1,
            abi.encodePacked("proof_data")
        );
        identityRegistry.consumeNullifier(NULLIFIER_1);

        vm.expectRevert("Nullifier already used");
        identityRegistry.consumeNullifier(NULLIFIER_1);
        vm.stopPrank();
    }

    function testCannotConsumeWithoutRegistration() public {
        vm.prank(user1);
        vm.expectRevert("Identity not registered");
        identityRegistry.consumeNullifier(NULLIFIER_1);
    }

    function testMultipleUsers() public {
        vm.prank(user1);
        identityRegistry.registerIdentity(
            IDENTITY_HASH_1,
            abi.encodePacked("proof_data_1")
        );

        vm.prank(user2);
        identityRegistry.registerIdentity(
            IDENTITY_HASH_2,
            abi.encodePacked("proof_data_2")
        );

        assertTrue(identityRegistry.isRegistered(user1));
        assertTrue(identityRegistry.isRegistered(user2));
        assertEq(identityRegistry.getIdentityHash(user1), IDENTITY_HASH_1);
        assertEq(identityRegistry.getIdentityHash(user2), IDENTITY_HASH_2);
    }

    function testGetRegistrationTimestamp() public {
        uint256 timestamp = block.timestamp;

        vm.prank(user1);
        identityRegistry.registerIdentity(
            IDENTITY_HASH_1,
            abi.encodePacked("proof_data")
        );

        assertEq(
            identityRegistry.getRegistrationTimestamp(user1),
            timestamp
        );
    }
}

