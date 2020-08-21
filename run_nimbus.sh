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

NAT_FLAG="--nat:none"
if [ "${NAT:-}" == "1" ]; then
  NAT_FLAG="--nat:any"
fi

rm -rf "$NIMBUS_DATA_DIR/dump"
mkdir -p "$NIMBUS_DATA_DIR/dump"

trap 'kill -9 -- -$$' SIGINT EXIT SIGTERM

BOOTNODES_ARG=""
if [[ -f $TESTNET_DIR/bootstrap_nodes.txt ]]; then
  BOOTNODES_ARG="--bootstrap-file=$TESTNET_DIR/bootstrap_nodes.txt"
fi

set -m # job control
set -x # print commands
$NIMBUS_BIN \
  --log-level=${LOG_LEVEL:-TRACE;TRACE:networking,bufferstream,mplex} \
  --log-file="$SIM_ROOT/nimbus.log" \
  --data-dir:$NIMBUS_DATA_DIR \
  --tcp-port:$PORT \
  --udp-port:$PORT \
  $BOOTNODES_ARG $NAT_FLAG \
  --state-snapshot:$TESTNET_DIR/genesis.ssz \
  --metrics
set +x

wait_and_register_enr "${NIMBUS_DATA_DIR}/beacon_node.enr"
fg
