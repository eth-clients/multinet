#!/bin/bash

set -eo pipefail

# Nimbus path
SRCDIR=${NIMBUS_PATH:-"nim-beacon-chain"}

# Read in variables
cd "$(dirname "$0")"
source vars.sh

# Cleanup interop data
cd "$SIM_ROOT"

rm -rf "$DATA_DIR"
mkdir -p "$DATA_DIR"

mkdir -p "$VALIDATORS_DIR" $"SECRETS_DIR"

# Cloning Nimbus if needed
[[ -d "$SRCDIR" ]] || {
  git clone -b devel https://github.com/status-im/nim-beacon-chain "$SRCDIR"
  pushd "${SRCDIR}"
  # Initial submodule update
  export GIT_LFS_SKIP_SMUDGE=1
  git submodule update --init --recursive
  popd
}

# Switching to Nimbus folder
cd "${SRCDIR}"

# Setup Nimbus build system environment variables
source env.sh

build_once "nimbus_submodules" make update

PRESET_FILE="${SIM_ROOT}/${SPEC_VERSION}.yaml"
DEPOSITS_GENERATOR="${BUILD_DIR}/deposit_maker"

# Build Nimbus
build_once "nimbus_beacon_node" \
  ./env.sh nim c -o:"$NIMBUS_BIN" $NIMFLAGS beacon_chain/beacon_node

build_once "nimbus_deposit_maker" \
  ./env.sh nim c -o:"$DEPOSITS_GENERATOR" $NIMFLAGS beacon_chain/deposit_contract

