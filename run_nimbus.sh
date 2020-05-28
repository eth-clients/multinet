#!/bin/bash

set -eo pipefail

# Interop environment variable
VALIDATORS_START=${1:-32}
VALIDATORS_NUM=${2:-32}
VALIDATORS_TOTAL=${3:-64}

source "$(dirname "$0")/vars.sh"

# Nimbus path
SRCDIR=${NIMBUS_PATH:-"nim-beacon-chain"}

# Cloning Nimbus if needed
[[ -d "$SRCDIR" ]] || {
  git clone https://github.com/status-im/nim-beacon-chain "$SRCDIR"
  pushd "${SRCDIR}"
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

# For interop, we run the minimal config
DEFS="-d:const_preset=minimal"

# Build Nimbus
[[ -x "$BEACON_NODE_BIN" ]] || {
  echo "Building $BEACON_NODE_BIN ($DEFS)"
  nim c -o:"$BEACON_NODE_BIN" $NIMFLAGS $DEFS beacon_chain/beacon_node
}

DATA_DIR="${SIMULATION_DIR}/node-0"

V_PREFIX="${VALIDATORS_DIR}/v$(printf '%06d' 0)"
PORT=$(printf '5%04d' 0)

NAT_FLAG="--nat:none"
if [ "${NAT:-}" == "1" ]; then
  NAT_FLAG="--nat:any"
fi

mkdir -p $DATA_DIR/validators
rm -f $DATA_DIR/validators/*

pushd $VALIDATORS_DIR >/dev/null
  cp $(seq -s " " -f v%07g.privkey $VALIDATORS_START $((VALIDATORS_START+VALIDATORS_NUM-1))) $DATA_DIR/validators
popd >/dev/null

rm -rf "$DATA_DIR/dump"
mkdir -p "$DATA_DIR/dump"

set -x
trap 'kill -9 -- -$$' SIGINT EXIT SIGTERM

$BEACON_NODE_BIN \
  --log-level=${LOG_LEVEL:-DEBUG} \
  --data-dir:$DATA_DIR \
  --node-name:0 \
  --tcp-port:$PORT \
  --udp-port:$PORT \
  $NAT_FLAG \
  --state-snapshot:$SNAPSHOT_FILE \
  --metrics \
  --verify-finalization
