#!/bin/bash

set -eu

source vars.sh

NBC_DATADIR="/root/multinet/repo/deposits/nimbus"

VALIDATORS_START=${1:-0}
VALIDATORS_NUM=${2:-64}
VALIDATORS_TOTAL=${3:-64}

SRCDIR=${PRYSM_PATH:-"prysm"}

command -v bazel > /dev/null || { echo "install bazel build tool first (https://docs.bazel.build/versions/master/install.html)"; exit 1; }
command -v go > /dev/null || { echo "install go first (https://golang.org/doc/install)"; exit 1; }

# This script assumes amd64. Prysm builds for other architectures, but keeping it simple
# for this start script.
OS=""
if [[ "$OSTYPE" == "linux-gnu" ]]; then
  OS+="linux_amd64"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  OS+="darwin_amd64"
else
  # Windows builds do work, but it would make this script more complicated.
  # Allowing for Mac and Linux only for the moment.
  echo "Only Mac and Linux builds supported at this time"
fi

[[ -d "$SRCDIR" ]] || {
  git clone https://github.com/prysmaticlabs/prysm.git "$SRCDIR"
  pushd "$SRCDIR"
  #bazel build --define ssz=minimal //beacon-chain //validator
  popd
}

set -x

cd "$SRCDIR"

rm -rf /tmp/beacon-prysm

# Wait nimbus (bootstrap node)
wait_enr "$NBC_DATADIR/beacon_node.enr"

sleep 2

BOOTNODES_ARG=""
if [[ -f $TESTNET_DIR/bootstrap_nodes.txt ]]; then
  BOOTNODES_ARG="--bootstrap-node=$(cat $TESTNET_DIR/bootstrap_nodes.txt | paste -s -d, -)"
fi

# needs a mock contract or will not like it
# 0x0 did not work

bazel run //beacon-chain -- \
  $BOOTNODES_ARG \
  --disable-discv5 \
  --force-clear-db \
  --datadir /tmp/beacon-prysm \
  --pprof \
  --verbosity debug \
  --interop-eth1data-votes \
  --chain-config-file $TESTNET_DIR/config.yaml \
  --contract-deployment-block 0 \
  --deposit-contract 0x8A04d14125D0FDCDc742F4A05C051De07232EDa4 \ 
  --interop-genesis-state $TESTNET_DIR/genesis.ssz #&

# sleep 3

# #"$(bazel info bazel-bin)/validator/${OS}_pure_stripped/validator"

# bazel run //validator -- \
#   --interop-start-index=$VALIDATORS_START \
#   --interop-num-validators=$VALIDATORS_NUM
