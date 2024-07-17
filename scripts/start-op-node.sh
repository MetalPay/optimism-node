#!/bin/sh
set -eou

# Wait for the Bedrock flag for this network to be set.
echo "Waiting for Bedrock node to initialize..."
while [ ! -f /shared/initialized.txt ]; do
  sleep 1
done

# Start op-node.
exec op-node \
  --l1=$OP_NODE__RPC_ENDPOINT \
  --l1.beacon=$OP_NODE__L1_BEACON \
  --override.fjord=1720627201
