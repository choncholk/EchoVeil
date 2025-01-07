#!/bin/bash
# Generate gas usage report

forge test --gas-report > gas_report.txt
echo "Gas report generated: gas_report.txt"

