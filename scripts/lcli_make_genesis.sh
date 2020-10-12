#!/bin/bash

set -eo pipefail

# Nimbus path
SRCDIR=${NIMBUS_PATH:-"nimbus-eth2"}
LIGHTHOUSE_DIR=${LIGHTHOUSE_DIR:-"lighthouse"}

# Read in variables
source "$(dirname "$0")/vars.sh"

# Cleanup interop data
cd "$SIM_ROOT"

rm -rf "$DATA_DIR"
mkdir -p "$TESTNET_DIR" "$VALIDATORS_DIR" "$SECRETS_DIR"

[[ -d "$LIGHTHOUSE_DIR" ]] || {
  git clone -b master https://github.com/sigp/lighthouse.git "$LIGHTHOUSE_DIR"
}

cd "$LIGHTHOUSE_DIR"
cargo build --release --all
make install-lcli

cd "target/release"
# fresh start!
rm -rf ~/.lighthouse

NOW=$(date +%s)
GENESIS_TIME=$((NOW + 30))

# make the testnet - same as here: https://github.com/sigp/lighthouse/blob/61496d8dad41525db95920737125c2942e07592c/scripts/local_testnet/setup.sh
# `--max-effective-balance` because the default is 3.2 ETH and not 32 ETH
./lcli \
  --spec $SPEC_VERSION \
  new-testnet \
  --deposit-contract-address 0000000000000000000000000000000000000000 \
  --testnet-dir $TESTNET_DIR \
  --force \
  --max-effective-balance 32000000000

./lcli \
  insecure-validators \
  --count $NUM_VALIDATORS \
  --validators-dir $VALIDATORS_DIR \
  --secrets-dir $SECRETS_DIR

./lcli \
  --spec $SPEC_VERSION \
  interop-genesis \
  --testnet-dir $TESTNET_DIR \
  $NUM_VALIDATORS \
  -t $GENESIS_TIME

echo 0 > $TESTNET_DIR/deposit_contract_block.txt
echo 0x0000000000000000000000000000000000000000 > $TESTNET_DIR/deposit_contract.txt
cp "${SIM_ROOT}/${SPEC_VERSION}.yaml" "$TESTNET_DIR/config.yaml"

