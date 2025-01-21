// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IGuardianMultisig {
    function submitTransaction(address target, uint256 value, bytes calldata data) external returns (uint256);
    function confirmTransaction(uint256 txId) external;
    function executeTransaction(uint256 txId) external;
    function revokeConfirmation(uint256 txId) external;
    function getGuardianCount() external view returns (uint256);
    function isGuardian(address account) external view returns (bool);
}

