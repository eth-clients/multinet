#!/bin/bash

set -eo pipefail

# Clone Nimbus Eth 2
SRCDIR=${NIMBUS_PATH:-"nim-beacon-chain"}

# Read in variables
source "$(dirname "$0")/vars.sh"

# Cleanup interop data
cd "$SIM_ROOT"

rm -rf "$SIMULATION_DIR"
mkdir -p "$SIMULATION_DIR"
mkdir -p "$VALIDATORS_DIR"

# Cloning Nimbus
[[ -d "$SRCDIR" ]] || {
  git clone https://github.com/status-im/nim-beacon-chain "$SRCDIR"
  pushd "$SRCDIR"
  # Initial submodule update
  export GIT_LFS_SKIP_SMUDGE=1
  git submodule update --init --recursive
  popd
}

# Switching to Nimbus folder
cd "${SRCDIR}"

# Setup Nimbus build system environment variables
source env.sh

# Update submodules
make update deps

# Compilation flags
NIMFLAGS="-d:chronicles_log_level=DEBUG --warnings:off --hints:off --opt:speed"

# For interop, we run the minimal config
DEFS="-d:const_preset=minimal"

# Build Nimbus
LAST_VALIDATOR_NUM=$(( NUM_VALIDATORS - 1 ))
LAST_VALIDATOR="$VALIDATORS_DIR/v$(printf '%07d' $LAST_VALIDATOR_NUM).deposit.json"

[[ -x "$BEACON_NODE_BIN" ]] || {
  echo "Building $BEACON_NODE_BIN ($DEFS)"
  nim c -o:"$BEACON_NODE_BIN" $NIMFLAGS $DEFS beacon_chain/beacon_node
}

# Generate deposits
if [ ! -f "${LAST_VALIDATOR}" ]; then
  $BEACON_NODE_BIN makeDeposits \
    --total-deposits="${NUM_VALIDATORS}" \
    --deposits-dir="$VALIDATORS_DIR" \
    --random-keys=no
fi

# Generate genesis file
if [ ! -f "${SNAPSHOT_FILE}" ]; then
  $BEACON_NODE_BIN \
    --data-dir="${SIMULATION_DIR}/node-0" \
    createTestnet \
    --validators-dir="${VALIDATORS_DIR}" \
    --total-validators="${NUM_VALIDATORS}" \
    --output-genesis="${SNAPSHOT_FILE}" \
    --output-bootstrap-file="${SIMULATION_DIR}/bootstrap_nodes.txt" \
    --bootstrap-address=127.0.0.1 \
    --bootstrap-port=50000 \
    --genesis-offset=30 # Delay in seconds
fi

# Delete any leftover address files from a previous session
if [ -f "${MASTER_NODE_ADDRESS_FILE}" ]; then
  rm "${MASTER_NODE_ADDRESS_FILE}"
fi
