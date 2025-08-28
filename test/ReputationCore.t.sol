// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/core/ReputationCore.sol";

contract ReputationCoreTest is Test {
    ReputationCore public reputationCore;
    address public guardian;
    address public oracle;
    bytes32 public constant INITIAL_ROOT = keccak256("initial_root");
    bytes32 public constant NEW_ROOT = keccak256("new_root");

    function setUp() public {
        guardian = address(0x1111);
        oracle = address(0x2222);

        reputationCore = new ReputationCore(guardian, oracle, INITIAL_ROOT);
    }

    function testInitialState() public {
        assertEq(reputationCore.getCurrentRoot(), INITIAL_ROOT);
        assertEq(reputationCore.getCurrentEpoch(), 0);
        assertTrue(reputationCore.isValidRoot(INITIAL_ROOT));
        assertEq(reputationCore.getRootAtEpoch(0), INITIAL_ROOT);
    }

    function testUpdateRootByOracle() public {
        vm.prank(oracle);
        reputationCore.updateRoot(NEW_ROOT);

        assertEq(reputationCore.getCurrentRoot(), NEW_ROOT);
        assertTrue(reputationCore.isValidRoot(NEW_ROOT));
    }

    function testUpdateRootByGuardian() public {
        vm.prank(guardian);
        reputationCore.updateRoot(NEW_ROOT);

        assertEq(reputationCore.getCurrentRoot(), NEW_ROOT);
        assertTrue(reputationCore.isValidRoot(NEW_ROOT));
    }

    function testCannotUpdateRootByUnauthorized() public {
        address unauthorized = address(0x3333);

        vm.prank(unauthorized);
        vm.expectRevert("Only oracle or guardian");
        reputationCore.updateRoot(NEW_ROOT);
    }

    function testAdvanceEpoch() public {
        // Fast forward time
        vm.warp(block.timestamp + 1 days);

        vm.prank(guardian);
        reputationCore.advanceEpoch();

        assertEq(reputationCore.getCurrentEpoch(), 1);
    }

    function testCannotAdvanceEpochTooEarly() public {
        vm.prank(guardian);
        vm.expectRevert("Epoch duration not elapsed");
        reputationCore.advanceEpoch();
    }

    function testCannotAdvanceEpochByNonGuardian() public {
        vm.warp(block.timestamp + 1 days);

        vm.prank(oracle);
        vm.expectRevert("Only guardian");
        reputationCore.advanceEpoch();
    }

    function testUpdateGuardian() public {
        address newGuardian = address(0x4444);

        vm.prank(guardian);
        reputationCore.updateGuardian(newGuardian);

        assertEq(reputationCore.guardian(), newGuardian);
    }

    function testUpdateOracle() public {
        address newOracle = address(0x5555);

        vm.prank(guardian);
        reputationCore.updateOracle(newOracle);

        assertEq(reputationCore.oracle(), newOracle);
    }

    function testTimeUntilNextEpoch() public {
        uint256 timeRemaining = reputationCore.timeUntilNextEpoch();
        assertEq(timeRemaining, 1 days);

        vm.warp(block.timestamp + 12 hours);
        timeRemaining = reputationCore.timeUntilNextEpoch();
        assertEq(timeRemaining, 12 hours);

        vm.warp(block.timestamp + 12 hours);
        timeRemaining = reputationCore.timeUntilNextEpoch();
        assertEq(timeRemaining, 0);
    }

    function testMultipleEpochTransitions() public {
        // Epoch 0 -> 1
        vm.warp(block.timestamp + 1 days);
        vm.prank(guardian);
        reputationCore.advanceEpoch();
        assertEq(reputationCore.getCurrentEpoch(), 1);

        // Update root in epoch 1
        bytes32 epoch1Root = keccak256("epoch_1_root");
        vm.prank(oracle);
        reputationCore.updateRoot(epoch1Root);

        // Epoch 1 -> 2
        vm.warp(block.timestamp + 1 days);
        vm.prank(guardian);
        reputationCore.advanceEpoch();
        assertEq(reputationCore.getCurrentEpoch(), 2);

        // Check historical roots
        assertEq(reputationCore.getRootAtEpoch(0), INITIAL_ROOT);
        assertEq(reputationCore.getRootAtEpoch(1), epoch1Root);
        assertEq(reputationCore.getRootAtEpoch(2), epoch1Root);
    }
}

Final test updates
