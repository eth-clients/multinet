# Multi-client interop scripts

Startup scripts for multiclient interop testnet.

## Running

Look in the scripts for options - the default config is a small setup using the `minimal` state spec.

⚠️ Nimbus startup script is being reworked to be stand-alone (previously multinet was run from within nimbus)

```
cd multinet

# Create a new genesis 10s in the future
./make_genesis.sh

# You can now start the clients
./run_nimbus.sh
./run_trinity.sh
./run_lighthouse.sh

# Or do all in one step, with multitail
USE_MULTITAIL=1 ./run_all.sh

# The client scripts take optional arguments:
# ./script.sh <start_validator_num> <number_of_validators> <total_validators>
./run_nimbus.sh 0 20 40 # run nimbus with 20 validators, starting from 0, on a 40-validator network
```

## Diagnostics

```bash
# Nimbus genesis state
less data/state_snapshot.json

# Lighthouse genesis state
curl localhost:5052/beacon/state?slot=0 | python -m json.tool | sed 's/"0x/"/' > /tmp/lighthouse_state.json

# Format nimbus the same
cat data/state_snapshot.json | python -m json.tool | sed 's/"0x/"/' > /tmp/nimbus_state.json

diff -uw /tmp/nimbus_state.json /tmp/lighthouse_state.json
```


# License

CC0 (Creative Common Zero)
