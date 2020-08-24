#!/bin/bash

set -eu
trap 'kill -9 -- -$$' SIGINT EXIT SIGTERM

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

bazel build //beacon-chain && bazel build //validator
