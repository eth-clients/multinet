#!/bin/bash

set -eu

# Read in variables
cd "$(dirname "$0")"
source vars.sh

LH_DATADIR="/root/multinet/repo/deposits/lighthouse"
NBC_DATADIR="/root/multinet/repo/deposits/nimbus"
LH_VALIDATORS_DIR=$LH_DATADIR/keys
LH_SECRETS_DIR=$LH_DATADIR/secrets

SRCDIR=${LIGHTHOUSE_PATH:-"lighthouse"}

pushd "$SRCDIR"
cargo build --release --all
popd

trap 'kill -9 -- -$$' SIGINT EXIT SIGTERM

cd "$SRCDIR/target/release"

# fresh start!
rm -rf ~/.lighthouse
rm -rf $LH_DATADIR/beacon

# Wait nimbus (bootstrap node)
wait_enr "$NBC_DATADIR/beacon_node.enr"

sleep 2

BOOTNODES_ARG=""
if [[ -f $TESTNET_DIR/bootstrap_nodes.txt ]]; then
  BOOTNODES_ARG="--boot-nodes $(cat $TESTNET_DIR/bootstrap_nodes.txt | paste -s -d, -)"
fi

if [[ -f $LH_DATADIR/beacon/pubkey_cache.ssz ]]; then
  rm $LH_DATADIR/beacon/pubkey_cache.ssz
fi

if [[ -f $LH_DATADIR/beacon/network/enr.dat ]]; then
  rm $LH_DATADIR/beacon/network/enr.dat
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
  --port 50001 \
  --enr-address lighthouse \
  --enr-udp-port 50001 \
  --http \
  $BOOTNODES_ARG 2>&1 | tee "$SIM_ROOT/lighthouse-node.log" &

# wait_and_register_enr "$LH_DATADIR/beacon/network/enr.dat"

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

