#!/bin/bash

set -eu

echo Locating zcli...
if ! command -v zcli; then
  go get -tags preset_minimal github.com/protolambda/zcli
fi

source "$(dirname "$0")/vars.sh"

# Fetch genesis time, as set up by start.sh
if command -v jq; then
  # requires the jq package for json parsing
  genesis_time=$(jq '.genesis_time' data/state_snapshot.json)
else
  # grep -P for perl parsing, not available on Mac
  genesis_time=$(grep -oP '(?<=genesis_time": )\w+(?=,)' data/state_snapshot.json)
fi

echo Genesis time was $genesis_time

zcli keys generate --to $NUM_VALIDATORS | zcli genesis mock --genesis-time $genesis_time --out data/zcli_genesis.ssz

zcli diff state data/zcli_genesis.ssz data/state_snapshot.ssz

# use this to diff against a lighthouse genesis
# zcli diff state ~/.lighthouse/local-testnet/testnet/genesis.ssz data/state_snapshot.ssz

