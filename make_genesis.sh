#!/bin/bash

set -eo pipefail

# Nimbus path
SRCDIR=${NIMBUS_PATH:-"nim-beacon-chain"}

# Read in variables
cd "$(dirname "$0")"
source vars.sh

# Cleanup interop data
cd "$SIM_ROOT"

rm -rf "$DATA_DIR"
mkdir -p "$DATA_DIR"

mkdir -p "$VALIDATORS_DIR" $"SECRETS_DIR"

# Cloning Nimbus if needed
[[ -d "$SRCDIR" ]] || {
  git clone -b devel https://github.com/status-im/nim-beacon-chain "$SRCDIR"
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

build_once "nimbus_submodules" make update

PRESET_FILE="${SIM_ROOT}/${SPEC_VERSION}.yaml"
DEPOSITS_GENERATOR="${BUILD_DIR}/deposit_maker"

# Build Nimbus
build_once "nimbus_beacon_node" \
  ./env.sh nim c -o:"$NIMBUS_BIN" $NIMFLAGS beacon_chain/beacon_node

build_once "nimbus_deposit_maker" \
  ./env.sh nim c -o:"$DEPOSITS_GENERATOR" $NIMFLAGS beacon_chain/deposit_contract

# Generate deposits
LAST_VALIDATOR_NUM=$(( NUM_VALIDATORS - 1 ))
LAST_VALIDATOR="$VALIDATORS_DIR/v$(printf '%07d' $LAST_VALIDATOR_NUM).deposit.json"

$DEPOSITS_GENERATOR generateSimulationDeposits \
  --count="${NUM_VALIDATORS}" \
  --out-validators-dir="$VALIDATORS_DIR" \
  --out-secrets-dir="$SECRETS_DIR" \
  --out-deposits-file="$DATA_DIR/deposits.json"

# Generate genesis file
if [ ! -f "${SNAPSHOT_FILE}" ]; then
  $NIMBUS_BIN \
    --data-dir="${DATA_DIR}/nimbus" \
    createTestnet \
    --deposits-file="$DATA_DIR/deposits.json" \
    --total-validators="${NUM_VALIDATORS}" \
    --output-genesis="${TESTNET_DIR}/genesis.ssz" \
    --output-bootstrap-file="${TESTNET_DIR}/bootstrap_nodes.txt" \
    --bootstrap-address=127.0.0.1 \
    --bootstrap-port=50000 \
    --genesis-offset=30 # Delay in seconds
fi

echo 0 > $TESTNET_DIR/deposit_contract_block.txt
echo 0 > $TESTNET_DIR/deploy_block.txt
echo 0x0000000000000000000000000000000000000000 > $TESTNET_DIR/deposit_contract.txt
cp "${SIM_ROOT}/${SPEC_VERSION}.yaml" "$TESTNET_DIR/config.yaml"

