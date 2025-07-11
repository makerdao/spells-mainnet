#!/bin/bash

# Exit on any error
set -e

# Check if required environment variables are set
if [ -z "$ETH_RPC_URL" ]; then
    echo "Error: ETH_RPC_URL environment variable is not set"
    exit 1
fi

if [ -z "$ETH_SENDER" ]; then
    echo "Error: ETH_SENDER environment variable is not set"
    exit 1
fi

echo "Starting anvil fork..."
# Start anvil in the background
anvil --auto-impersonate --fork-url "$ETH_RPC_URL" &
ANVIL_PID=$!

# Wait for anvil to start
echo "Waiting for anvil to start..."
sleep 5

echo "Funding sender address $ETH_SENDER..."
# Fund the sender address
curl http://localhost:8545 -X POST -H "Content-Type: application/json" \
  --data "{\"method\":\"anvil_setBalance\",\"params\":[\"$ETH_SENDER\", \"0x021e19e0c9bab2400000\"],\"id\":1,\"jsonrpc\":\"2.0\"}"

sleep 2

echo "Running SafeHarbor deploy script..."
# Run the deploy script
forge script DeployAgreement.s.sol:DeployAgreement \
  --rpc-url "127.0.0.1:8545" \
  --sender "$ETH_SENDER" \
  --broadcast \
  --slow \
  --unlocked \
  -vvvvv

echo "Deploy script completed successfully!"
echo "Anvil is still running in the background (PID: $ANVIL_PID)"
echo "To stop anvil, run: kill $ANVIL_PID"
echo "You can now run additional SafeHarbor scripts against this fork." 
