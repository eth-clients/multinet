#!/bin/bash

set -eu

# Read in variables
cd "$(dirname "$0")"
source vars.sh

LH_DATADIR="/root/multinet/repo/deposits/lighthouse"
LH_VALIDATORS_DIR=$LH_DATADIR/validators
LH_SECRETS_DIR=$LH_DATADIR/secrets

SRCDIR=${LIGHTHOUSE_PATH:-"lighthouse"}

pushd "$SRCDIR"
cargo build --release --all
popd

trap 'kill -9 -- -$$' SIGINT EXIT SIGTERM

cd "$SRCDIR/target/release"

# fresh start!
rm -rf ~/.lighthouse

BOOTNODES_ARG=""
if [[ -f $TESTNET_DIR/bootstrap_nodes.txt ]]; then
  BOOTNODES_ARG="--boot-nodes $(cat $TESTNET_DIR/bootstrap_nodes.txt | paste -s -d, -)"
fi

set -x # print commands
# beacon node
# TODO not sure if the RUST_LOG and the --debug-level options do the same thing...
#RUST_LOG=debug \
./lighthouse \
	--debug-level trace \
  bn \
	--datadir $LH_DATADIR \
  --testnet-dir $TESTNET_DIR \
  --dummy-eth1 \
  --spec $SPEC_VERSION \
  --enr-match \
  --http \
  $BOOTNODES_ARG 2>&1 | tee "$SIM_ROOT/lighthouse-node.log" &
set +x

wait_and_register_enr "$LH_DATADIR/beacon/network/enr.dat"

set -x # print commands
# validator client
./lighthouse \
	--debug-level info \
  vc \
  --spec $SPEC_VERSION \
	--datadir $LH_VALIDATORS_DIR \
	--secrets-dir $LH_SECRETS_DIR \
	--testnet-dir $TESTNET_DIR \
	--auto-register \
  --allow-unsynced 2>&1 | tee "$SIM_ROOT/lighthouse-vc.log"
set +x

