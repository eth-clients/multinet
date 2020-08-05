#!/bin/bash

PWD_CMD="pwd"
# get native Windows paths on Mingw
uname | grep -qi mingw && PWD_CMD="pwd -W"

cd $(dirname $0)

SIM_ROOT="$($PWD_CMD)"

# Set a default value for the env vars usually supplied by a Makefile
cd $(git rev-parse --show-toplevel)
: ${GIT_ROOT:="$($PWD_CMD)"}
cd - &>/dev/null

NUM_VALIDATORS=${VALIDATORS:-64}
NUM_NODES=${NODES:-1}
NUM_MISSING_NODES=${MISSING_NODES:-2}

DATA_DIR="${SIM_ROOT}/data"
TESTNET_DIR="${DATA_DIR}/testnet"
VALIDATORS_DIR="${TESTNET_DIR}/validators"
SECRETS_DIR="${TESTNET_DIR}/secrets"
NETWORK_BOOTSTRAP_FILE="${TESTNET_DIR}/bootstrap_nodes.txt"

ls_validators () {
  FIRST=$1
  LAST=$2

  RANGE_LEN=$((LAST - FIRST + 1))

  for VALIDATOR in $(ls ${VALIDATORS_DIR} | tail -n $((NUM_VALIDATORS - FIRST + 1)) | head -n $RANGE_LEN); do
    echo $VALIDATOR
  done
}
