// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IProofGateway.sol";
import "../interfaces/IZKVerifier.sol";
import "../interfaces/IReputationCore.sol";
import "../interfaces/IIdentityRegistry.sol";

/**
 * @title ProofGateway
 * @notice Unified interface for dApp proof verification
 * @dev Gateway contract that coordinates verification across system components
 */
contract ProofGateway is IProofGateway {
    /// @notice ZK Verifier contract
    IZKVerifier public immutable zkVerifier;

    /// @notice Reputation Core contract
    IReputationCore public immutable reputationCore;

    /// @notice Identity Registry contract
    IIdentityRegistry public immutable identityRegistry;

    /// @notice Mapping from nullifier to usage status
    mapping(bytes32 => bool) private usedNullifiers;

    /// @notice Mapping from user to their verification results
    mapping(address => mapping(bytes32 => VerificationResult)) 
        private verificationResults;

    /// @notice Mapping of registered dApps
    mapping(address => bool) private registeredDApps;

    /// @notice dApp metadata
    mapping(address => string) private dappMetadata;

    /**
     * @notice Constructor
     * @param _zkVerifier Address of ZK verifier
     * @param _reputationCore Address of reputation core
     * @param _identityRegistry Address of identity registry
     */
    constructor(
        address _zkVerifier,
        address _reputationCore,
        address _identityRegistry
    ) {
        require(_zkVerifier != address(0), "Invalid verifier");
        require(_reputationCore != address(0), "Invalid reputation core");
        require(_identityRegistry != address(0), "Invalid identity registry");

        zkVerifier = IZKVerifier(_zkVerifier);
        reputationCore = IReputationCore(_reputationCore);
        identityRegistry = IIdentityRegistry(_identityRegistry);
    }

    /**
     * @inheritdoc IProofGateway
     */
    function verifyEligibility(
        IZKVerifier.Proof calldata proof,
        EligibilityRequirement calldata requirement,
        bytes32 nullifier
    ) external override returns (VerificationResult memory) {
        require(nullifier != bytes32(0), "Invalid nullifier");
        require(!usedNullifiers[nullifier], "Nullifier already used");

        // Validate epoch and root
        require(
            requirement.epoch <= reputationCore.getCurrentEpoch(),
            "Invalid epoch"
        );
        require(
            reputationCore.isValidRoot(requirement.merkleRoot),
            "Invalid Merkle root"
        );

        // Verify the ZK proof
        bool proofValid;
        if (requirement.requireSybilResistance) {
            proofValid = zkVerifier.verifyEligibilityProof(
                proof,
                requirement.merkleRoot,
                requirement.minScore,
                nullifier
            );
        } else {
            // Create public signals for basic proof
            uint256[] memory publicSignals = new uint256[](3);
            publicSignals[0] = uint256(requirement.merkleRoot);
            publicSignals[1] = requirement.minScore;
            publicSignals[2] = uint256(nullifier);
            proofValid = zkVerifier.verifyReputationProof(proof, publicSignals);
        }

        // Mark nullifier as used if proof is valid
        if (proofValid) {
            usedNullifiers[nullifier] = true;
        }

        // Create verification result
        VerificationResult memory result = VerificationResult({
            success: proofValid,
            nullifier: nullifier,
            timestamp: block.timestamp,
            verifier: msg.sender
        });

        // Store result
        verificationResults[msg.sender][nullifier] = result;

        emit EligibilityVerified(msg.sender, proofValid, nullifier, block.timestamp);

        return result;
    }

    /**
     * @inheritdoc IProofGateway
     */
    function batchVerifyEligibility(
        IZKVerifier.Proof[] calldata proofs,
        EligibilityRequirement[] calldata requirements,
        bytes32[] calldata nullifiers
    ) external override returns (VerificationResult[] memory results) {
        require(
            proofs.length == requirements.length &&
            proofs.length == nullifiers.length,
            "Array length mismatch"
        );

        results = new VerificationResult[](proofs.length);

        for (uint256 i = 0; i < proofs.length; i++) {
            results[i] = this.verifyEligibility(
                proofs[i],
                requirements[i],
                nullifiers[i]
            );
        }

        return results;
    }

    /**
     * @inheritdoc IProofGateway
     */
    function isNullifierUsed(
        bytes32 nullifier
    ) external view override returns (bool) {
        return usedNullifiers[nullifier];
    }

    /**
     * @inheritdoc IProofGateway
     */
    function registerDApp(string calldata metadata) external override {
        require(!registeredDApps[msg.sender], "dApp already registered");
        require(bytes(metadata).length > 0, "Invalid metadata");

        registeredDApps[msg.sender] = true;
        dappMetadata[msg.sender] = metadata;

        emit DAppRegistered(msg.sender, block.timestamp);
    }

    /**
     * @inheritdoc IProofGateway
     */
    function getVerificationResult(
        address user,
        bytes32 nullifier
    ) external view override returns (VerificationResult memory) {
        return verificationResults[user][nullifier];
    }

    /**
     * @notice Check if a dApp is registered
     * @param dapp Address of the dApp
     * @return bool True if registered
     */
    function isDAppRegistered(address dapp) external view returns (bool) {
        return registeredDApps[dapp];
    }

    /**
     * @notice Get dApp metadata
     * @param dapp Address of the dApp
     * @return string Metadata URI
     */
    function getDAppMetadata(address dapp) external view returns (string memory) {
        return dappMetadata[dapp];
    }
}

