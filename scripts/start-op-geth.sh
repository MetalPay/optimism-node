#!/bin/sh
set -eou

# Wait for the Bedrock flag for this network to be set.
echo "Waiting for Bedrock node to initialize..."
while [ ! -f /shared/initialized.txt ]; do
  sleep 1
done

if [ -z "${IS_CUSTOM_CHAIN+x}" ]; then
  if [ "$NETWORK_NAME" == "op-mainnet" ] || [ "$NETWORK_NAME" == "op-goerli" ]; then
    export EXTENDED_ARG="${EXTENDED_ARG:-} --rollup.historicalrpc=${OP_GETH__HISTORICAL_RPC:-http://l2geth:8545} --op-network=$NETWORK_NAME"
  else
    export EXTENDED_ARG="${EXTENDED_ARG:-} --op-network=$NETWORK_NAME"
  fi
fi

# Init genesis if custom chain
CHAINDATA_DIR="$BEDROCK_DATADIR/geth/chaindata"

if [ ! -d "$CHAINDATA_DIR" ]; then
  echo "$CHAINDATA_DIR missing, running init"
  geth init --datadir="$BEDROCK_DATADIR" /chainconfig/genesis.json
else
	echo "$CHAINDATA_DIR exists."
fi

# Determine syncmode based on NODE_TYPE
if [ -z "${OP_GETH__SYNCMODE+x}" ]; then
  if [ "$NODE_TYPE" = "full" ]; then
    export OP_GETH__SYNCMODE="snap"
  else
    export OP_GETH__SYNCMODE="full"
  fi
fi

# Start op-geth.
exec geth \
  --datadir="$BEDROCK_DATADIR" \
  --http \
  --http.corsdomain="*" \
  --http.vhosts="*" \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.api=web3,debug,eth,txpool,net,engine \
  --ws \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --ws.origins="*" \
  --ws.api=debug,eth,txpool,net,engine,web3 \
  --metrics \
  --metrics.influxdb \
  --metrics.influxdb.endpoint=http://influxdb:8086 \
  --metrics.influxdb.database=opgeth \
  --syncmode="$OP_GETH__SYNCMODE" \
  --gcmode="$NODE_TYPE" \
  --authrpc.vhosts="*" \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=/shared/jwt.txt \
  --rollup.sequencerhttp="$BEDROCK_SEQUENCER_HTTP" \
  --rollup.disabletxpoolgossip=true \
  --port="${PORT__OP_GETH_P2P:-39393}" \
  --discovery.port="${PORT__OP_GETH_P2P:-39393}" \
  --networkid="${NETWORK_ID}" \
  --nodiscover \
  --nat=extip:0.0.0.0 \
  --override.fjord=1720627201 \
  $EXTENDED_ARG $@

