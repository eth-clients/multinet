#!/bin/bash

# Lighthouse genesis state - remove all occurances of '0x'
curl localhost:5052/beacon/state/genesis | python3 -m json.tool | sed 's/"0x/"/' > /tmp/lighthouse_state.json

# To get the lighthouse genesis state as a .ssz file use this:
# curl --header "Accept: application/ssz" "localhost:5052/beacon/state/genesis" --output path/to/lighthouse_genesis.ssz

# Format nimbus the same
cat data/state_snapshot.json | python3 -m json.tool | sed 's/"0x/"/' > /tmp/nimbus_state.json

diff -uw /tmp/nimbus_state.json /tmp/lighthouse_state.json

