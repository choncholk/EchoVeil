// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GuardianMultisig
 * @notice Multi-signature guardian contract for admin and emergency controls
 * @dev Implements threshold signature system for critical operations
 */
contract GuardianMultisig {
    /// @notice Minimum number of confirmations required
    uint256 public requiredConfirmations;

    /// @notice List of guardian addresses
    address[] public guardians;

    /// @notice Mapping to check if address is guardian
    mapping(address => bool) public isGuardian;

    /// @notice Transaction structure
    struct Transaction {
        address target;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    /// @notice Array of all transactions
    Transaction[] public transactions;

    /// @notice Mapping from transaction ID to guardian confirmations
    mapping(uint256 => mapping(address => bool)) public confirmations;

    /// @notice Emergency pause status
    bool public emergencyPaused;

    /**
     * @notice Emitted when transaction is submitted
     */
    event TransactionSubmitted(
        uint256 indexed txId,
        address indexed submitter,
        address target,
        uint256 value,
        bytes data
    );

    /**
     * @notice Emitted when transaction is confirmed
     */
    event TransactionConfirmed(
        uint256 indexed txId,
        address indexed guardian
    );

    /**
     * @notice Emitted when confirmation is revoked
     */
    event ConfirmationRevoked(
        uint256 indexed txId,
        address indexed guardian
    );

    /**
     * @notice Emitted when transaction is executed
     */
    event TransactionExecuted(uint256 indexed txId);

    /**
     * @notice Emitted when guardian is added
     */
    event GuardianAdded(address indexed guardian);

    /**
     * @notice Emitted when guardian is removed
     */
    event GuardianRemoved(address indexed guardian);

    /**
     * @notice Emitted when emergency pause is triggered
     */
    event EmergencyPauseTriggered(address indexed guardian);

    /**
     * @notice Only guardian can call
     */
    modifier onlyGuardian() {
        require(isGuardian[msg.sender], "Not a guardian");
        _;
    }

    /**
     * @notice Transaction must exist
     */
    modifier txExists(uint256 txId) {
        require(txId < transactions.length, "Transaction does not exist");
        _;
    }

    /**
     * @notice Transaction must not be executed
     */
    modifier notExecuted(uint256 txId) {
        require(!transactions[txId].executed, "Transaction already executed");
        _;
    }

    /**
     * @notice Transaction must not be confirmed by sender
     */
    modifier notConfirmed(uint256 txId) {
        require(
            !confirmations[txId][msg.sender],
            "Transaction already confirmed"
        );
        _;
    }

    /**
     * @notice Constructor
     * @param _guardians Array of initial guardian addresses
     * @param _requiredConfirmations Number of required confirmations
     */
    constructor(address[] memory _guardians, uint256 _requiredConfirmations) {
        require(_guardians.length > 0, "Guardians required");
        require(
            _requiredConfirmations > 0 &&
            _requiredConfirmations <= _guardians.length,
            "Invalid required confirmations"
        );

        for (uint256 i = 0; i < _guardians.length; i++) {
            address guardian = _guardians[i];
            require(guardian != address(0), "Invalid guardian address");
            require(!isGuardian[guardian], "Duplicate guardian");

            isGuardian[guardian] = true;
            guardians.push(guardian);
            emit GuardianAdded(guardian);
        }

        requiredConfirmations = _requiredConfirmations;
    }

    /**
     * @notice Submit a new transaction
     * @param target Target contract address
     * @param value ETH value to send
     * @param data Transaction data
     * @return txId Transaction ID
     */
    function submitTransaction(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyGuardian returns (uint256 txId) {
        txId = transactions.length;

        transactions.push(
            Transaction({
                target: target,
                value: value,
                data: data,
                executed: false,
                confirmations: 0
            })
        );

        emit TransactionSubmitted(txId, msg.sender, target, value, data);
    }

    /**
     * @notice Confirm a transaction
     * @param txId Transaction ID
     */
    function confirmTransaction(
        uint256 txId
    ) external onlyGuardian txExists(txId) notExecuted(txId) notConfirmed(txId) {
        confirmations[txId][msg.sender] = true;
        transactions[txId].confirmations++;

        emit TransactionConfirmed(txId, msg.sender);
    }

    /**
     * @notice Execute a confirmed transaction
     * @param txId Transaction ID
     */
    function executeTransaction(
        uint256 txId
    ) external onlyGuardian txExists(txId) notExecuted(txId) {
        Transaction storage transaction = transactions[txId];

        require(
            transaction.confirmations >= requiredConfirmations,
            "Insufficient confirmations"
        );

        transaction.executed = true;

        (bool success, ) = transaction.target.call{value: transaction.value}(
            transaction.data
        );
        require(success, "Transaction execution failed");

        emit TransactionExecuted(txId);
    }

    /**
     * @notice Revoke confirmation
     * @param txId Transaction ID
     */
    function revokeConfirmation(
        uint256 txId
    ) external onlyGuardian txExists(txId) notExecuted(txId) {
        require(
            confirmations[txId][msg.sender],
            "Transaction not confirmed"
        );

        confirmations[txId][msg.sender] = false;
        transactions[txId].confirmations--;

        emit ConfirmationRevoked(txId, msg.sender);
    }

    /**
     * @notice Trigger emergency pause
     */
    function triggerEmergencyPause() external onlyGuardian {
        emergencyPaused = true;
        emit EmergencyPauseTriggered(msg.sender);
    }

    /**
     * @notice Get guardian count
     * @return uint256 Number of guardians
     */
    function getGuardianCount() external view returns (uint256) {
        return guardians.length;
    }

    /**
     * @notice Get transaction count
     * @return uint256 Number of transactions
     */
    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    /**
     * @notice Check if transaction is confirmed by guardian
     * @param txId Transaction ID
     * @param guardian Guardian address
     * @return bool True if confirmed
     */
    function isConfirmed(
        uint256 txId,
        address guardian
    ) external view returns (bool) {
        return confirmations[txId][guardian];
    }

    /**
     * @notice Receive ETH
     */
    receive() external payable {}
}

