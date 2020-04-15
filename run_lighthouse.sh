#!/bin/bash

# https://github.com/sigp/lighthouse/blob/master/docs/interop.md

set -eu

VALIDATORS_START=${1:-0}
VALIDATORS_NUM=${2:-64}
VALIDATORS_TOTAL=${3:-64}

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
  git clone -b v0.2.0 https://github.com/sigp/lighthouse.git "$SRCDIR"
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

#$export RUST_LOG=libp2p=trace,multistream=trace,gossipsub=trace

# fresh start!
rm -rf ~/.lighthouse

# make the testnet
# --genesis-fork-version: because the spec doesn't currently affect the genesis fork version
# --max-effective-balance: because the default for lcli is 3.2 ETH and not 32 ETH
./lcli -s minimal new-testnet --genesis-fork-version 0x00000001 --max-effective-balance 32000000000
./lcli -s minimal interop-genesis $VALIDATORS_TOTAL -t $GENESIS_TIME

# beacon node
./lighthouse bn -t ~/.lighthouse/testnet --spec minimal --http &

# for now lighthouse would run alone with all of the validators by default - add this to the
# beacon node in order to find nimbus: --boot-nodes "$(cat ../../../data/bootstrap_nodes.txt)"

./lighthouse vc -t ~/.lighthouse/testnet --spec minimal testnet insecure $VALIDATORS_START $VALIDATORS_NUM
