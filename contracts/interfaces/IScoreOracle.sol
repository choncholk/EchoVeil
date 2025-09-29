// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IScoreOracle
 * @notice Interface for Score Oracle contract
 */
interface IScoreOracle {
    event RootUpdateProposed(bytes32 indexed newRoot, uint256 timestamp, address operator);
    event RootUpdateExecuted(bytes32 indexed newRoot, uint256 timestamp);
    event OraclePaused(address guardian, uint256 timestamp);
    event OracleUnpaused(address guardian, uint256 timestamp);

    function proposeRootUpdate(bytes32 newRoot) external;
    function executeRootUpdate() external;
    function emergencyUpdateRoot(bytes32 newRoot) external;
    function pause() external;
    function unpause() external;
    function timeUntilNextUpdate() external view returns (uint256);
}

