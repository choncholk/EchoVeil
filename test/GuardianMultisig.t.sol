// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/governance/GuardianMultisig.sol";

contract GuardianMultisigTest is Test {
    GuardianMultisig public multisig;
    address[] public guardians;
    uint256 public constant REQUIRED_CONFIRMATIONS = 2;

    address public guardian1;
    address public guardian2;
    address public guardian3;

    function setUp() public {
        guardian1 = address(0x1111);
        guardian2 = address(0x2222);
        guardian3 = address(0x3333);

        guardians = new address[](3);
        guardians[0] = guardian1;
        guardians[1] = guardian2;
        guardians[2] = guardian3;

        multisig = new GuardianMultisig(guardians, REQUIRED_CONFIRMATIONS);
    }

    function testInitialState() public {
        assertEq(multisig.requiredConfirmations(), REQUIRED_CONFIRMATIONS);
        assertEq(multisig.getGuardianCount(), 3);
        assertTrue(multisig.isGuardian(guardian1));
        assertTrue(multisig.isGuardian(guardian2));
        assertTrue(multisig.isGuardian(guardian3));
    }

    function testSubmitTransaction() public {
        vm.prank(guardian1);
        uint256 txId = multisig.submitTransaction(
            address(0x4444),
            1 ether,
            ""
        );

        assertEq(txId, 0);
        assertEq(multisig.getTransactionCount(), 1);
    }

    function testConfirmTransaction() public {
        vm.prank(guardian1);
        uint256 txId = multisig.submitTransaction(address(0x4444), 0, "");

        vm.prank(guardian2);
        multisig.confirmTransaction(txId);

        assertTrue(multisig.isConfirmed(txId, guardian2));
    }

    function testExecuteTransaction() public {
        vm.prank(guardian1);
        uint256 txId = multisig.submitTransaction(address(0x4444), 0, "");

        vm.prank(guardian1);
        multisig.confirmTransaction(txId);

        vm.prank(guardian2);
        multisig.confirmTransaction(txId);

        vm.prank(guardian3);
        multisig.executeTransaction(txId);
    }

    function testCannotExecuteWithoutConfirmations() public {
        vm.prank(guardian1);
        uint256 txId = multisig.submitTransaction(address(0x4444), 0, "");

        vm.prank(guardian1);
        vm.expectRevert("Insufficient confirmations");
        multisig.executeTransaction(txId);
    }

    function testRevokeConfirmation() public {
        vm.prank(guardian1);
        uint256 txId = multisig.submitTransaction(address(0x4444), 0, "");

        vm.prank(guardian2);
        multisig.confirmTransaction(txId);

        vm.prank(guardian2);
        multisig.revokeConfirmation(txId);

        assertFalse(multisig.isConfirmed(txId, guardian2));
    }
}

