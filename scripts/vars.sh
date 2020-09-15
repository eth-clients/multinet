#!/bin/bash

PWD_CMD="pwd"
# get native Windows paths on Mingw
uname | grep -qi mingw && PWD_CMD="pwd -W"

cd $(dirname $0)

SIM_ROOT="$($PWD_CMD)"

# # Set a default value for the env vars usually supplied by a Makefile
# cd $(git rev-parse --show-toplevel)
# : ${GIT_ROOT:="$($PWD_CMD)"}
# cd - &>/dev/null

SPEC_VERSION=mainnet

NUM_VALIDATORS=${VALIDATORS:-64}
NUM_NODES=${NODES:-1}
NUM_MISSING_NODES=${MISSING_NODES:-2}

DATA_DIR="${SIM_ROOT}/data"
BUILD_DIR="${SIM_ROOT}/build"
TESTNET_DIR="${DATA_DIR}/testnet"
VALIDATORS_DIR="${TESTNET_DIR}/validators"
SECRETS_DIR="${TESTNET_DIR}/secrets"
NETWORK_BOOTSTRAP_FILE="${TESTNET_DIR}/bootstrap_nodes.txt"
PRESET_FILE=${SIM_ROOT}/${SPEC_VERSION}.yaml

NIMFLAGS="-d:insecure -d:chronicles_log_level=TRACE --warnings:off --hints:off --opt:speed -d:disableMarchNative -d:const_preset=$PRESET_FILE"
NIMBUS_BIN="${BUILD_DIR}/nimbus"

ls_validators () {
  FIRST=$1
  LAST=$2

  RANGE_LEN=$((LAST - FIRST + 1))

  for VALIDATOR in $(ls ${VALIDATORS_DIR} | tail -n $((NUM_VALIDATORS - FIRST + 1)) | head -n $RANGE_LEN); do
    echo $VALIDATOR
  done
}

wait_file () {
  MSG_DISPLAYED=0
  while [ ! -f "$1" ]; do
    if (( MSG_DISPLAYED == 0 )); then
      echo "Waiting for $1 to appear..."
      MSG_DISPLAYED=1
    fi
    sleep 0.1
  done
  echo "Waiting for $1 ended."
}

wait_and_register_enr () {
  echo "Registering ENR"
  wait_file "$1"
  # # Add a new line just in case
  # echo >> $TESTNET_DIR/bootstrap_nodes.txt
  cat "$1" >> $TESTNET_DIR/bootstrap_nodes.txt
}

wait_enr () {
  echo "Waiting ENR"
  wait_file "$1"
}

build_once () {
  BUILD_TASK=$1
  shift
  BUILD_CMD=$@

  if [ -z "$(git status --porcelain)" ]; then
    # Working directory is clean
    GIT_REV=$(git rev-parse --short HEAD)
    PREV_BUILD_MARKER="$GIT_ROOT/.git/build.$BUILD_TASK.$GIT_REV"
    if [ ! -f $PREV_BUILD_MARKER ]; then
      set -x # print commands
      $BUILD_CMD
      set +x
      echo 1 > $PREV_BUILD_MARKER
    fi
  else
    # When the working copy is dirty, we run a regular uncached build
    set -x # print commands
    $BUILD_CMD
    set +x
  fi
}
