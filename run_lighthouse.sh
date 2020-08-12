#!/bin/bash

# https://github.com/sigp/lighthouse/blob/master/docs/interop.md

export RUST_LOG=trace,libp2p=trace,multistream=trace,gossipsub=trace

set -eu

# unfortunately we cannot use VALIDATORS_START just like with the rest of the clients - with
# lighthouse it's easy to generate the mock deterministic keys but it's no longer easy to tell
# it which range of keys to use (perhaps that could be done by deleting the other
# ranges, but...) and that's why lighthouse always starts from 0
VALIDATORS_START=${1:-0}
VALIDATORS_NUM=${2:-32}
VALIDATORS_TOTAL=${3:-64}

# Read in variables
cd "$(dirname "$0")"
source vars.sh

LH_DATADIR=$(pwd)/data/lighthouse
LH_TESTNET_DIR=$LH_DATADIR/testnet
LH_BEACON_DIR=$LH_DATADIR/beacon
LH_VALIDATORS_DIR=$LH_DATADIR/validators
LH_SECRETS_DIR=$LH_DATADIR/secrets

rm -rf "$LH_DATADIR"
mkdir -p "$LH_TESTNET_DIR" "$LH_VALIDATORS_DIR" "$LH_SECRETS_DIR"

for validator in $(ls_validators 33 64)
do
  mkdir -p $LH_VALIDATORS_DIR/$validator
  cp $VALIDATORS_DIR/$validator/*keystore.json $LH_VALIDATORS_DIR/$validator/voting-keystore.json
  cp $SECRETS_DIR/$validator $LH_SECRETS_DIR/
done

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

