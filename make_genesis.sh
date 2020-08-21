#!/bin/bash

set -eo pipefail

# Nimbus path
SRCDIR=${NIMBUS_PATH:-"nim-beacon-chain"}

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

# Generate deposits
LAST_VALIDATOR_NUM=$(( NUM_VALIDATORS - 1 ))
LAST_VALIDATOR="$VALIDATORS_DIR/v$(printf '%07d' $LAST_VALIDATOR_NUM).deposit.json"

$DEPOSITS_GENERATOR generateSimulationDeposits \
  --count="${NUM_VALIDATORS}" \
  --out-validators-dir="$VALIDATORS_DIR" \
  --out-secrets-dir="$SECRETS_DIR" \
  --out-deposits-file="$DATA_DIR/deposits.json"

# Generate genesis file
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


echo 0 > $TESTNET_DIR/deposit_contract_block.txt
echo 0 > $TESTNET_DIR/deploy_block.txt
echo 0x0000000000000000000000000000000000000000 > $TESTNET_DIR/deposit_contract.txt
cp "${SIM_ROOT}/${SPEC_VERSION}.yaml" "$TESTNET_DIR/config.yaml"
