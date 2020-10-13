#!/bin/bash

echo "Running nimbus"

set -eo pipefail
set -x # print commands

source "$(dirname "$0")/vars.sh"

# Nimbus path
NIMBUS_DIR=${NIMBUS_PATH:-"nimbus-eth2"}

MULTINET_POD_NAME=${MULTINET_POD_NAME:-nimbus-0}
NIMBUS_DATA_DIR="/root/multinet/repo/deposits/$MULTINET_POD_NAME"

chmod -R 750 "$NIMBUS_DATA_DIR"
chmod -R 600 "$NIMBUS_DATA_DIR/validators"
chmod -R 600 "$NIMBUS_DATA_DIR/secrets"

# Switching to Nimbus folder
cd "${NIMBUS_DIR}"

# Setup Nimbus build system environment variables
source env.sh

./env.sh nim c -o:"$NIMBUS_BIN" $NIMFLAGS beacon_chain/beacon_node

PORT=$(printf '5%04d' 0)

NAT_FLAG="--nat:extip:172.20.0.10"
if [ "$MULTINET_POD_IP" != "" ]; then
  NAT_FLAG="--nat:extip:$MULTINET_POD_IP";
fi

rm -rf "$NIMBUS_DATA_DIR/db"
rm -f "$NIMBUS_DATA_DIR/beacon_node.enr"
rm -f "$NIMBUS_DATA_DIR/genesis.ssz"
rm -rf "$NIMBUS_DATA_DIR/dump"
mkdir -p "$NIMBUS_DATA_DIR/dump"

BOOTNODES_ARG=""
if [[ -f $TESTNET_DIR/bootstrap_nodes.txt ]]; then
  BOOTNODES_ARG="--bootstrap-file=$TESTNET_DIR/bootstrap_nodes.txt"
fi

if [ "$MULTINET_POD_NAME" == "nimbus-0" ]; then
  wait_and_register_enr "$NIMBUS_DATA_DIR/beacon_node.enr" &
fi

$NIMBUS_BIN \
  --log-level=$LOG_LEVEL \
  --log-file="$SIM_ROOT/nimbus.log" \
  --data-dir:$NIMBUS_DATA_DIR \
  --tcp-port:$PORT \
  --udp-port:$PORT \
  --rpc \
  --rpc-address="0.0.0.0" \
  --rpc-port=7000 \
  $BOOTNODES_ARG $NAT_FLAG \
  --finalized-checkpoint-state:$TESTNET_DIR/genesis.ssz \
  --metrics
