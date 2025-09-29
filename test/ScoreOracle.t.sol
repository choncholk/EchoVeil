// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/oracle/ScoreOracle.sol";
import "../contracts/core/ReputationCore.sol";

contract ScoreOracleTest is Test {
    ScoreOracle public scoreOracle;
    ReputationCore public reputationCore;

    address public guardian;
    address public operator;
    bytes32 public constant INITIAL_ROOT = keccak256("initial");
    bytes32 public constant NEW_ROOT = keccak256("new_root");

    function setUp() public {
        guardian = address(0x1111);
        operator = address(0x2222);

        reputationCore = new ReputationCore(guardian, operator, INITIAL_ROOT);
        scoreOracle = new ScoreOracle(
            address(reputationCore),
            operator,
            guardian
        );

        // Update reputation core to allow oracle to update roots
        vm.prank(guardian);
        reputationCore.updateOracle(address(scoreOracle));
    }

    function testInitialState() public {
        assertEq(scoreOracle.operator(), operator);
        assertEq(scoreOracle.guardian(), guardian);
        assertFalse(scoreOracle.paused());
    }

    function testProposeRootUpdate() public {
        vm.warp(block.timestamp + 1 days);

        vm.prank(operator);
        scoreOracle.proposeRootUpdate(NEW_ROOT);

        (bytes32 root, uint256 timestamp, bool executed) = scoreOracle.pendingUpdate();
        assertEq(root, NEW_ROOT);
        assertEq(timestamp, block.timestamp);
        assertFalse(executed);
    }

    function testCannotProposeTooEarly() public {
        vm.prank(operator);
        vm.expectRevert("Update cooldown not elapsed");
        scoreOracle.proposeRootUpdate(NEW_ROOT);
    }

    function testExecuteRootUpdate() public {
        // Propose
        vm.warp(block.timestamp + 1 days);
        vm.prank(operator);
        scoreOracle.proposeRootUpdate(NEW_ROOT);

        // Wait for timelock
        vm.warp(block.timestamp + 1 hours);

        // Execute
        vm.prank(operator);
        scoreOracle.executeRootUpdate();

        assertEq(reputationCore.getCurrentRoot(), NEW_ROOT);
    }

    function testCannotExecuteBeforeTimelock() public {
        vm.warp(block.timestamp + 1 days);
        vm.prank(operator);
        scoreOracle.proposeRootUpdate(NEW_ROOT);

        vm.prank(operator);
        vm.expectRevert("Timelock not elapsed");
        scoreOracle.executeRootUpdate();
    }

    function testEmergencyUpdateRoot() public {
        vm.prank(guardian);
        scoreOracle.emergencyUpdateRoot(NEW_ROOT);

        assertEq(reputationCore.getCurrentRoot(), NEW_ROOT);
    }

    function testPauseUnpause() public {
        vm.prank(guardian);
        scoreOracle.pause();
        assertTrue(scoreOracle.paused());

        vm.prank(guardian);
        scoreOracle.unpause();
        assertFalse(scoreOracle.paused());
    }

    function testCannotOperateWhenPaused() public {
        vm.prank(guardian);
        scoreOracle.pause();

        vm.warp(block.timestamp + 1 days);
        vm.prank(operator);
        vm.expectRevert("Oracle is paused");
        scoreOracle.proposeRootUpdate(NEW_ROOT);
    }

    function testUpdateOperator() public {
        address newOperator = address(0x3333);

        vm.prank(guardian);
        scoreOracle.updateOperator(newOperator);

        assertEq(scoreOracle.operator(), newOperator);
    }

    function testTransferGuardian() public {
        address newGuardian = address(0x4444);

        vm.prank(guardian);
        scoreOracle.transferGuardian(newGuardian);

        assertEq(scoreOracle.guardian(), newGuardian);
    }

    function testTimeUntilNextUpdate() public {
        uint256 timeRemaining = scoreOracle.timeUntilNextUpdate();
        assertEq(timeRemaining, 1 days);

        vm.warp(block.timestamp + 12 hours);
        timeRemaining = scoreOracle.timeUntilNextUpdate();
        assertEq(timeRemaining, 12 hours);

        vm.warp(block.timestamp + 12 hours);
        timeRemaining = scoreOracle.timeUntilNextUpdate();
        assertEq(timeRemaining, 0);
    }

    function testTimeUntilExecution() public {
        vm.warp(block.timestamp + 1 days);
        vm.prank(operator);
        scoreOracle.proposeRootUpdate(NEW_ROOT);

        uint256 timeRemaining = scoreOracle.timeUntilExecution();
        assertEq(timeRemaining, 1 hours);

        vm.warp(block.timestamp + 30 minutes);
        timeRemaining = scoreOracle.timeUntilExecution();
        assertEq(timeRemaining, 30 minutes);

        vm.warp(block.timestamp + 30 minutes);
        timeRemaining = scoreOracle.timeUntilExecution();
        assertEq(timeRemaining, 0);
    }

    function testOnlyOperatorCanPropose() public {
        vm.warp(block.timestamp + 1 days);

        vm.prank(address(0x9999));
        vm.expectRevert("Only operator");
        scoreOracle.proposeRootUpdate(NEW_ROOT);
    }

    function testOnlyGuardianCanPause() public {
        vm.prank(operator);
        vm.expectRevert("Only guardian");
        scoreOracle.pause();
    }

    function testOnlyGuardianCanEmergencyUpdate() public {
        vm.prank(operator);
        vm.expectRevert("Only guardian");
        scoreOracle.emergencyUpdateRoot(NEW_ROOT);
    }

    function testMultipleUpdateCycle() public {
        // First update
        vm.warp(block.timestamp + 1 days);
        vm.prank(operator);
        scoreOracle.proposeRootUpdate(NEW_ROOT);

        vm.warp(block.timestamp + 1 hours);
        vm.prank(operator);
        scoreOracle.executeRootUpdate();

        // Second update
        bytes32 secondRoot = keccak256("second_root");
        vm.warp(block.timestamp + 1 days);
        vm.prank(operator);
        scoreOracle.proposeRootUpdate(secondRoot);

        vm.warp(block.timestamp + 1 hours);
        vm.prank(operator);
        scoreOracle.executeRootUpdate();

        assertEq(reputationCore.getCurrentRoot(), secondRoot);
    }

    function testEmergencyUpdateClearsPending() public {
        vm.warp(block.timestamp + 1 days);
        vm.prank(operator);
        scoreOracle.proposeRootUpdate(NEW_ROOT);

        bytes32 emergencyRoot = keccak256("emergency");
        vm.prank(guardian);
        scoreOracle.emergencyUpdateRoot(emergencyRoot);

        (bytes32 root, , ) = scoreOracle.pendingUpdate();
        assertEq(root, bytes32(0));
    }
}

