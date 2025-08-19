// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/core/IdentityRegistry.sol";
import "../contracts/core/ReputationCore.sol";
import "../contracts/core/ZKVerifier.sol";
import "../contracts/core/ProofGateway.sol";
import "../contracts/oracle/ScoreOracle.sol";
import "../contracts/governance/GuardianMultisig.sol";

/**
 * @title DeployScript
 * @notice Deployment script for EchoVeil protocol
 */
contract DeployScript is Script {
    // Deployment addresses (will be updated during deployment)
    address public identityRegistry;
    address public reputationCore;
    address public zkVerifier;
    address public proofGateway;
    address public scoreOracle;
    address public guardianMultisig;

    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying from:", deployer);
        console.log("Balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Guardian Multisig first
        address[] memory initialGuardians = new address[](3);
        initialGuardians[0] = deployer;
        initialGuardians[1] = vm.envAddress("GUARDIAN_ADDRESS");
        initialGuardians[2] = deployer; // Can be replaced later
        
        guardianMultisig = address(
            new GuardianMultisig(initialGuardians, 2)
        );
        console.log("GuardianMultisig deployed at:", guardianMultisig);

        // Deploy ZK Verifier
        bytes32 verifyingKeyHash = keccak256("echoveil_circuit_v1");
        zkVerifier = address(new ZKVerifier(verifyingKeyHash, false));
        console.log("ZKVerifier deployed at:", zkVerifier);

        // Deploy Identity Registry
        identityRegistry = address(new IdentityRegistry(zkVerifier));
        console.log("IdentityRegistry deployed at:", identityRegistry);

        // Deploy Reputation Core
        bytes32 initialRoot = keccak256("initial_merkle_root");
        reputationCore = address(
            new ReputationCore(
                guardianMultisig,
                deployer, // Temporary oracle, will be replaced
                initialRoot
            )
        );
        console.log("ReputationCore deployed at:", reputationCore);

        // Deploy Score Oracle
        scoreOracle = address(
            new ScoreOracle(
                reputationCore,
                deployer, // Oracle operator
                guardianMultisig
            )
        );
        console.log("ScoreOracle deployed at:", scoreOracle);

        // Update Reputation Core to use Score Oracle
        // This would be done through guardian multisig in production

        // Deploy Proof Gateway
        proofGateway = address(
            new ProofGateway(
                zkVerifier,
                reputationCore,
                identityRegistry
            )
        );
        console.log("ProofGateway deployed at:", proofGateway);

        vm.stopBroadcast();

        // Log all deployment addresses
        console.log("\n=== Deployment Summary ===");
        console.log("GuardianMultisig:", guardianMultisig);
        console.log("ZKVerifier:", zkVerifier);
        console.log("IdentityRegistry:", identityRegistry);
        console.log("ReputationCore:", reputationCore);
        console.log("ScoreOracle:", scoreOracle);
        console.log("ProofGateway:", proofGateway);
        console.log("========================\n");

        // Save addresses to file for verification
        string memory deploymentInfo = string(
            abi.encodePacked(
                "GUARDIAN_MULTISIG=", vm.toString(guardianMultisig), "\n",
                "ZK_VERIFIER=", vm.toString(zkVerifier), "\n",
                "IDENTITY_REGISTRY=", vm.toString(identityRegistry), "\n",
                "REPUTATION_CORE=", vm.toString(reputationCore), "\n",
                "SCORE_ORACLE=", vm.toString(scoreOracle), "\n",
                "PROOF_GATEWAY=", vm.toString(proofGateway), "\n"
            )
        );

        vm.writeFile("deployment.txt", deploymentInfo);
        console.log("Deployment addresses saved to deployment.txt");
    }
}

Deploy polish
