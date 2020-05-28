#!/bin/bash

# https://github.com/sigp/lighthouse/blob/master/docs/interop.md

set -eu

# unfortunately we cannot use VALIDATORS_START just like with the rest of the clients - with
# lighthouse it's easy to generate the mock deterministic keys but it's no longer easy to tell
# it which range of keys to use (perhaps that could be done by deleting the other
# ranges, but...) and that's why lighthouse always starts from 0
VALIDATORS_START=${1:-0}
VALIDATORS_NUM=${2:-32}
VALIDATORS_TOTAL=${3:-64}

LH_DATADIR=~/.lighthouse/local-testnet
LH_TESTNET_DIR=$LH_DATADIR/testnet
LH_BEACON_DIR=$LH_DATADIR/beacon
LH_VALIDATORS_DIR=$LH_DATADIR/validators
LH_SECRETS_DIR=$LH_DATADIR/secrets

source "$(dirname "$0")/vars.sh"

SRCDIR=${LIGHTHOUSE_PATH:-"lighthouse"}

# Make sure you also have the development packages of openssl installed.
# For example, `libssl-dev` on Ubuntu or `openssl-devel` on Fedora.

echo Locating protoc...
if ! command -v protoc; then
  MSG="protoc (the Google Protobuf compiler) is missing. Please install it manually"
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    MSG+=" with sudo apt install protobuf-compiler"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    MSG+=" with 'brew install protobuf'"
  elif [[ "$OSTYPE" == "cygwin" ]]; then
    # POSIX compatibility layer and Linux environment emulation for Windows
    MSG+=""
  elif [[ "$OSTYPE" == "msys" ]]; then
    # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
    MSG+=""
  elif [[ "$OSTYPE" == "win32" ]]; then
    # I'm not sure this can happen.
    MSG+=""
  elif [[ "$OSTYPE" == "freebsd"* ]]; then
    # ...
    MSG+=""
  else
    # Unknown.
    MSG+=""
  fi
  echo $MSG
  exit 1
fi

command -v cargo > /dev/null || { echo "install rust first (https://rust-lang.org)"; exit 1; }

[[ -d "$SRCDIR" ]] || {
  git clone -b master https://github.com/sigp/lighthouse.git "$SRCDIR"
}

pushd "$SRCDIR"
cargo build --release --all
popd

# Fetch genesis time, as set up by start.sh
if command -v jq > /dev/null; then
  GENESIS_TIME=$(jq '.genesis_time' data/state_snapshot.json)
else
  GENESIS_TIME=$(grep -oP '(?<=genesis_time": )\w+(?=,)' data/state_snapshot.json)
fi

echo Genesis time was $GENESIS_TIME

set -x
trap 'kill -9 -- -$$' SIGINT EXIT SIGTERM

cd "$SRCDIR/target/release"

#$export RUST_LOG=debug,libp2p=trace,multistream=trace,gossipsub=trace

# fresh start!
rm -rf ~/.lighthouse

# make the testnet - same as here: https://github.com/sigp/lighthouse/blob/61496d8dad41525db95920737125c2942e07592c/scripts/local_testnet/setup.sh
# `--max-effective-balance` because the default is 3.2 ETH and not 32 ETH
./lcli \
  -s minimal \
  new-testnet \
  --deposit-contract-address 0000000000000000000000000000000000000000 \
	--testnet-dir $LH_TESTNET_DIR \
  --max-effective-balance 32000000000

./lcli \
	insecure-validators \
	--count $VALIDATORS_NUM \
	--validators-dir $LH_VALIDATORS_DIR \
	--secrets-dir $LH_SECRETS_DIR

./lcli \
  -s minimal \
  interop-genesis \
	--testnet-dir $LH_TESTNET_DIR \
  $VALIDATORS_TOTAL \
  -t $GENESIS_TIME

# beacon node
# TODO not sure if the RUST_LOG and the --debug-level options do the same thing...
#RUST_LOG=debug \
./lighthouse \
	--debug-level info \
  bn \
	--testnet-dir $LH_TESTNET_DIR \
  --dummy-eth1 \
  --spec minimal \
  --enr-match \
  --http \
  --boot-nodes "$(cat ../../../data/bootstrap_nodes.txt)" &

sleep 5 # enough time for the BN to be up so that the VC can connect to it

# validator client
./lighthouse \
	--debug-level info \
  vc \
  --spec minimal \
	--datadir $LH_VALIDATORS_DIR \
	--secrets-dir $LH_SECRETS_DIR \
	--testnet-dir $LH_TESTNET_DIR \
	--auto-register \
  --allow-unsynced
