#!/bin/bash

set -eo pipefail

# Nimbus path
SRCDIR=${NIMBUS_PATH:-"nim-beacon-chain"}
DEPOSITS_DIR="/root/multinet/repo/deposits"

NUM_VALIDATORS=96

# Read in variables
cd "$(dirname "$0")"
source vars.sh

# Cleanup interop data
cd "$SIM_ROOT"

mkdir -p "$DATA_DIR"
mkdir -p "$VALIDATORS_DIR" $"SECRETS_DIR"

# Switching to Nimbus folder
cd "${SRCDIR}"

# Setup Nimbus build system environment variables
source env.sh

build_once "nimbus_submodules" make update

PRESET_FILE="${SIM_ROOT}/${SPEC_VERSION}.yaml"
DEPOSITS_GENERATOR="${BUILD_DIR}/deposit_maker"

# Generate genesis file
$NIMBUS_BIN \
  --data-dir="${DATA_DIR}/nimbus" \
  createTestnet \
  --deposits-file=$DEPOSITS_DIR/deposits.json \
  --total-validators=$NUM_VALIDATORS \
  --output-genesis="${TESTNET_DIR}/genesis.ssz" \
  --output-bootstrap-file="${TESTNET_DIR}/bootstrap_nodes.txt" \
  --bootstrap-address=172.20.0.10 \
  --bootstrap-port=50000 \
  --genesis-offset=30 # Delay in seconds

echo "Genesis is ready!"


# do not use this, it's wrong
# will cause:
# got error on dial: failed to negotiate security protocol: peer id mismatch: expected 16Uiu2HAmULPTzyRTVh6zoW9KZ3zEYow1nfHMiZX6prihTudv2tKG, but remote key matches 16Uiu2HAmFoKBrhv5f3xF5V4LH91d4qLuJ89SJs5kyCA7ZUgDAVrM
rm -f "${TESTNET_DIR}/bootstrap_nodes.txt" 

echo 0 > $TESTNET_DIR/deposit_contract_block.txt
echo 0 > $TESTNET_DIR/deploy_block.txt
echo 0x0000000000000000000000000000000000000000 > $TESTNET_DIR/deposit_contract.txt
cp "${SIM_ROOT}/${SPEC_VERSION}.yaml" "$TESTNET_DIR/config.yaml"
