#!/bin/bash

set -eo pipefail

source "$(dirname "$0")/vars.sh"

# Nimbus path
NIMBUS_DIR=${NIMBUS_PATH:-"nim-beacon-chain"}

NIMBUS_DATA_DIR="${DATA_DIR}/nimbus"
NIMBUS_VALIDATORS_DIR="${NIMBUS_DATA_DIR}/validators"
NIMBUS_SECRETS_DIR="${NIMBUS_DATA_DIR}/secrets"

BEACON_NODE_BIN="${NIMBUS_DATA_DIR}/beacon_node"

# Compilation flags
NIMFLAGS="-d:insecure -d:chronicles_log_level=TRACE --warnings:off --hints:off --opt:speed"
#-d:libp2p_secure=noise

mkdir -p "$NIMBUS_VALIDATORS_DIR" "$NIMBUS_SECRETS_DIR"

for validator in $(ls_validators 1 50)
do
  mkdir -p $NIMBUS_VALIDATORS_DIR/$validator
  cp $VALIDATORS_DIR/$validator/*keystore.json \
    $NIMBUS_VALIDATORS_DIR/$validator/keystore.json

  cp $SECRETS_DIR/$validator $NIMBUS_SECRETS_DIR
done

# Cloning Nimbus if needed
[[ -d "$NIMBUS_DIR" ]] || {
  git clone https://github.com/status-im/nim-beacon-chain "$NIMBUS_DIR"
  pushd "${NIMBUS_DIR}"
  # Initial submodule update
  export GIT_LFS_SKIP_SMUDGE=1
  git submodule update --init --recursive
  popd
}

# Switching to Nimbus folder
cd "${NIMBUS_DIR}"

# Setup Nimbus build system environment variables
source env.sh

# Update submodules
make update deps

DEFS="-d:const_preset=${SPEC_VERSION}"

echo "Building $BEACON_NODE_BIN ($DEFS)"
./env.sh nim c -o:"$BEACON_NODE_BIN" $NIMFLAGS $DEFS beacon_chain/beacon_node

PORT=$(printf '5%04d' 0)

NAT_FLAG="--nat:none"
if [ "${NAT:-}" == "1" ]; then
  NAT_FLAG="--nat:any"
fi

rm -rf "$NIMBUS_DATA_DIR/dump"
mkdir -p "$NIMBUS_DATA_DIR/dump"

set -x
trap 'kill -9 -- -$$' SIGINT EXIT SIGTERM

$BEACON_NODE_BIN \
  --log-level=${LOG_LEVEL:-DEBUG} \
  --data-dir:$NIMBUS_DATA_DIR \
  --tcp-port:$PORT \
  --udp-port:$PORT \
  $NAT_FLAG \
  --state-snapshot:$TESTNET_DIR/genesis.ssz \
  --metrics \
  --verify-finalization

