#!/bin/bash

set -eo pipefail

source "$(dirname "$0")/vars.sh"

# Nimbus path
NIMBUS_DIR=${NIMBUS_PATH:-"nim-beacon-chain"}

NIMBUS_DATA_DIR="/root/multinet/repo/deposits/nimbus" # static docker path

# Switching to Nimbus folder
cd "${NIMBUS_DIR}"

# Setup Nimbus build system environment variables
source env.sh

build_once "nimbus_submodules" make update
build_once "nimbus_beacon_node" \
  ./env.sh nim c -o:"$NIMBUS_BIN" $NIMFLAGS beacon_chain/beacon_node

PORT=$(printf '5%04d' 0)

NAT_FLAG="--nat:extip:172.20.0.10"

rm -rf "$NIMBUS_DATA_DIR/db"
rm -f "$NIMBUS_DATA_DIR/beacon_node.enr"
rm -f "$NIMBUS_DATA_DIR/genesis.ssz"
rm -rf "$NIMBUS_DATA_DIR/dump"
mkdir -p "$NIMBUS_DATA_DIR/dump"

BOOTNODES_ARG=""
if [[ -f $TESTNET_DIR/bootstrap_nodes.txt ]]; then
  BOOTNODES_ARG="--bootstrap-file=$TESTNET_DIR/bootstrap_nodes.txt"
fi

set -x # print commands

wait_and_register_enr "$NIMBUS_DATA_DIR/beacon_node.enr" &

$NIMBUS_BIN \
  --log-level=$LOG_LEVEL \
  --log-file="$SIM_ROOT/nimbus.log" \
  --data-dir:$NIMBUS_DATA_DIR \
  --tcp-port:$PORT \
  --udp-port:$PORT \
  $BOOTNODES_ARG $NAT_FLAG \
  --state-snapshot:$TESTNET_DIR/genesis.ssz \
  --metrics