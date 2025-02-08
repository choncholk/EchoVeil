#!/bin/bash
# Clean build artifacts

forge clean
rm -rf out/ cache/ broadcast/
echo "Build artifacts cleaned"

