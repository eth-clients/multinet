#!/bin/bash

set -eo pipefail

source "$(dirname "$0")/vars.sh"

# Nimbus path
NIMBUS_DIR=${NIMBUS_PATH:-"nim-beacon-chain"}

NIMBUS_DATA_DIR="${DATA_DIR}/nimbus"
NIMBUS_VALIDATORS_DIR="${NIMBUS_DATA_DIR}/validators"
NIMBUS_SECRETS_DIR="${NIMBUS_DATA_DIR}/secrets"

if ((1)); then
  # rm -rf "$NIMBUS_DATA_DIR"
  mkdir -p "$NIMBUS_VALIDATORS_DIR" "$NIMBUS_SECRETS_DIR"

  for validator in $(ls_validators 1 32)
  do
    mkdir -p $NIMBUS_VALIDATORS_DIR/$validator
    cp $VALIDATORS_DIR/$validator/*keystore.json \
      $NIMBUS_VALIDATORS_DIR/$validator/keystore.json

    cp $SECRETS_DIR/$validator $NIMBUS_SECRETS_DIR
  done
fi

# Cloning Nimbus if needed
[[ -d "$NIMBUS_DIR" ]] || {
  git clone https://github.com/status-im/nim-beacon-chain "$NIMBUS_DIR"
  pushd "${NIMBUS_DIR}"
  git checkout devel
  # Initial submodule update
  export GIT_LFS_SKIP_SMUDGE=1
  git submodule update --init --recursive
  popd
}

# Switching to Nimbus folder
cd "${NIMBUS_DIR}"

# Setup Nimbus build system environment variables
source env.sh

build_once "nimbus_submodules" make update
build_once "nimbus_beacon_node" \
  ./env.sh nim c -o:"$NIMBUS_BIN" $NIMFLAGS beacon_chain/beacon_node
