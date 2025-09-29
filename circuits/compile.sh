#!/bin/bash

# EchoVeil ZK Circuit Compilation Script
# Compiles circom circuits and generates verification keys

set -e

CIRCUIT_NAME="reputation_proof"
BUILD_DIR="build"
PTAU_FILE="powersOfTau28_hez_final_20.ptau"

echo "=== EchoVeil Circuit Compilation ==="
echo "Circuit: $CIRCUIT_NAME"
echo ""

# Create build directory
mkdir -p $BUILD_DIR

# Step 1: Compile circuit
echo "[1/7] Compiling circuit..."
circom ${CIRCUIT_NAME}.circom --r1cs --wasm --sym --c -o $BUILD_DIR

# Step 2: View circuit info
echo "[2/7] Circuit info:"
snarkjs r1cs info ${BUILD_DIR}/${CIRCUIT_NAME}.r1cs

# Step 3: Download powers of tau (if not exists)
if [ ! -f "$BUILD_DIR/$PTAU_FILE" ]; then
    echo "[3/7] Downloading powers of tau..."
    cd $BUILD_DIR
    wget https://hermez.s3-eu-west-1.amazonaws.com/$PTAU_FILE
    cd ..
else
    echo "[3/7] Powers of tau already downloaded"
fi

# Step 4: Generate zkey (Groth16 proving key)
echo "[4/7] Generating zkey..."
snarkjs groth16 setup ${BUILD_DIR}/${CIRCUIT_NAME}.r1cs ${BUILD_DIR}/$PTAU_FILE ${BUILD_DIR}/${CIRCUIT_NAME}_0000.zkey

# Step 5: Contribute to phase 2 ceremony
echo "[5/7] Contributing to ceremony..."
snarkjs zkey contribute ${BUILD_DIR}/${CIRCUIT_NAME}_0000.zkey ${BUILD_DIR}/${CIRCUIT_NAME}_final.zkey --name="First contribution" -v -e="$(openssl rand -hex 32)"

# Step 6: Export verification key
echo "[6/7] Exporting verification key..."
snarkjs zkey export verificationkey ${BUILD_DIR}/${CIRCUIT_NAME}_final.zkey ${BUILD_DIR}/verification_key.json

# Step 7: Generate Solidity verifier
echo "[7/7] Generating Solidity verifier..."
snarkjs zkey export solidityverifier ${BUILD_DIR}/${CIRCUIT_NAME}_final.zkey ${BUILD_DIR}/Verifier.sol

echo ""
echo "=== Compilation Complete ==="
echo "Build directory: $BUILD_DIR"
echo "R1CS: ${BUILD_DIR}/${CIRCUIT_NAME}.r1cs"
echo "WASM: ${BUILD_DIR}/${CIRCUIT_NAME}_js/${CIRCUIT_NAME}.wasm"
echo "Proving key: ${BUILD_DIR}/${CIRCUIT_NAME}_final.zkey"
echo "Verification key: ${BUILD_DIR}/verification_key.json"
echo "Solidity verifier: ${BUILD_DIR}/Verifier.sol"
echo ""
echo "Next steps:"
echo "1. Copy Verifier.sol to contracts/core/"
echo "2. Update ZKVerifier contract to use generated verifier"
echo "3. Test proof generation and verification"

