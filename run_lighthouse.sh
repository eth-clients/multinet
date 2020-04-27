#!/bin/bash

# https://github.com/sigp/lighthouse/blob/master/docs/interop.md

set -eu

VALIDATORS_START=${1:-32}
VALIDATORS_NUM=${2:-32}
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
  git clone -b interop_genesis_fork_version_fix https://github.com/onqtam/lighthouse.git "$SRCDIR"
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

#$export RUST_LOG=debug .

# fresh start!
rm -rf ~/.lighthouse


# lcli --spec mainnet new-testnet \
# --deposit-contract-address 5cA1e00004366Ac85f492887AAab12d0e6418876 \
# --deposit-contract-deploy-block 2523557 \
# --effective-balance-increment 1000000000 \
# --ejection-balance 16000000000 \
# --eth1-follow-distance 1024 \
# --genesis-fork-version 0x00000000 \
# --min-deposit-amount 1000000000 \
# --min-genesis-active-validator-count 16384 \
# --min-genesis-delay 86400 \
# --min-genesis-time 1578009600 \
# --testnet-dir ~/.lighthouse/topaz

# make the testnet
# --max-effective-balance: because the default for lcli is 3.2 ETH and not 32 ETH
./lcli -s minimal new-testnet --deposit-contract-address 0000000000000000000000000000000000000000 --max-effective-balance 32000000000
./lcli -s minimal interop-genesis $VALIDATORS_TOTAL -t $GENESIS_TIME

# beacon node
RUST_LOG=debug ./lighthouse bn -t ~/.lighthouse/testnet --dummy-eth1 --spec minimal --enr-match --http --boot-nodes "$(cat ../../../data/bootstrap_nodes.txt)" #&

# for now lighthouse would run alone with all of the validators by default - add this to the
# beacon node in order to find nimbus: --boot-nodes "$(cat ../../../data/bootstrap_nodes.txt)"

./lighthouse vc -t ~/.lighthouse/testnet --spec minimal --allow-unsynced testnet insecure $VALIDATORS_START $VALIDATORS_NUM
