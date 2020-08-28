#!/bin/bash

GO_PATH=/root/multinet/go

NIMBUS_VALIDATORS=${NIMBUS_VALIDATORS:-32}
LIGHTHOUSE_VALIDATORS=${LIGHTHOUSE_VALIDATORS:-32}
PRYSM_VALIDATORS=${PRYSM_VALIDATORS:-32}

FORK_VERSION=0x00000000
DEPOSIT_AMOUNT=32000000000
WITHDRAWALS_MNEMONIC="enough animal salon barrel poet method husband evidence grain excuse grass science there wedding blind glimpse surge loan reopen chalk toward change survey bag"
VALIDATORS_MNEMONIC="stay depend ignore lady access will dress idea hybrid tube original riot between plate ethics ecology green response hollow famous salute they warrior little"

rm -rf /root/multinet/repo/deposits
mkdir -p /root/multinet/repo/deposits

VALIDATOR_OFFSET=0

# DEPOSITS FIRST

# Nimbus

$GO_PATH/bin/eth2-val-tools deposit-data \
--source-min=$VALIDATOR_OFFSET \
--source-max=$(($VALIDATOR_OFFSET + $NIMBUS_VALIDATORS)) \
--amount="$DEPOSIT_AMOUNT" \
--fork-version="$FORK_VERSION" \
--withdrawals-mnemonic="$WITHDRAWALS_MNEMONIC" \
--validators-mnemonic="$VALIDATORS_MNEMONIC" > /root/multinet/repo/deposits/assignments.json 2>&1

$GO_PATH/bin/eth2-val-tools assign \
  --assignments="/root/multinet/repo/deposits/assignments.json" \
  --hostname="multinet" \
  --out-loc="/root/multinet/repo/deposits/nimbus" \
  --source-mnemonic="$VALIDATORS_MNEMONIC" \
  --source-min=0 \
  --source-max=32 \
  --count=32 \
  --config-base-path="/root/multinet/repo/deposits" \
  --key-man-loc="/root/multinet/repo/deposits/wallets" \
  --wallet-name="multinet-wallet"

mv /root/multinet/repo/deposits/nimbus/nimbus-keys /root/multinet/repo/deposits/nimbus/validators

VALIDATOR_OFFSET=$(($VALIDATOR_OFFSET + $NIMBUS_VALIDATORS))

# LH

$GO_PATH/bin/eth2-val-tools deposit-data \
--source-min=$VALIDATOR_OFFSET \
--source-max=$(($VALIDATOR_OFFSET + $LIGHTHOUSE_VALIDATORS)) \
--amount="$DEPOSIT_AMOUNT" \
--fork-version="$FORK_VERSION" \
--withdrawals-mnemonic="$WITHDRAWALS_MNEMONIC" \
--validators-mnemonic="$VALIDATORS_MNEMONIC" > /root/multinet/repo/deposits/assignments.json 2>&1

$GO_PATH/bin/eth2-val-tools assign \
  --assignments="/root/multinet/repo/deposits/assignments.json" \
  --hostname="multinet" \
  --out-loc="/root/multinet/repo/deposits/lighthouse" \
  --source-mnemonic="$VALIDATORS_MNEMONIC" \
  --source-min=32 \
  --source-max=64 \
  --count=32 \
  --config-base-path="/root/multinet/repo/deposits" \
  --key-man-loc="/root/multinet/repo/deposits/wallets" \
  --wallet-name="multinet-wallet"

VALIDATOR_OFFSET=$(($VALIDATOR_OFFSET + $LIGHTHOUSE_VALIDATORS))

# Prysm

$GO_PATH/bin/eth2-val-tools deposit-data \
--source-min=$VALIDATOR_OFFSET \
--source-max=$(($VALIDATOR_OFFSET + $PRYSM_VALIDATORS)) \
--amount="$DEPOSIT_AMOUNT" \
--fork-version="$FORK_VERSION" \
--withdrawals-mnemonic="$WITHDRAWALS_MNEMONIC" \
--validators-mnemonic="$VALIDATORS_MNEMONIC" > /root/multinet/repo/deposits/assignments.json 2>&1

$GO_PATH/bin/eth2-val-tools assign \
  --assignments="/root/multinet/repo/deposits/assignments.json" \
  --hostname="multinet" \
  --out-loc="/root/multinet/repo/deposits/prysm" \
  --source-mnemonic="$VALIDATORS_MNEMONIC" \
  --source-min=64 \
  --source-max=96 \
  --count=32 \
  --config-base-path="/root/multinet/repo/deposits" \
  --key-man-loc="/root/multinet/repo/deposits/wallets" \
  --wallet-name="multinet-wallet"

VALIDATOR_OFFSET=$(($VALIDATOR_OFFSET + $PRYSM_VALIDATORS))

echo "Total validators $VALIDATOR_OFFSET."

# redo assigments on all 96 to convert it into nimbus deposits.json

$GO_PATH/bin/eth2-val-tools deposit-data \
--source-min=0 \
--source-max=$VALIDATOR_OFFSET \
--amount="$DEPOSIT_AMOUNT" \
--fork-version="$FORK_VERSION" \
--withdrawals-mnemonic="$WITHDRAWALS_MNEMONIC" \
--validators-mnemonic="$VALIDATORS_MNEMONIC" > /root/multinet/repo/deposits/assignments.json 2>&1

cat /root/multinet/repo/deposits/assignments.json \
| jq -s '.' \
| jq 'map({pubkey:.pubkey, signature:.signature,withdrawal_credentials:.withdrawal_credentials,amount:.value})' \
> /root/multinet/repo/deposits/deposits.json

echo "Deposits done."

# GENESIS STATE

# Nimbus path
SRCDIR=${NIMBUS_PATH:-"nim-beacon-chain"}
DEPOSITS_DIR="/root/multinet/repo/deposits"

NUM_VALIDATORS=$VALIDATOR_OFFSET

# Read in variables
cd "$(dirname "$0")"
source vars.sh

# Cleanup interop data
cd "$SIM_ROOT"

mkdir -p "$DATA_DIR"
mkdir -p "$VALIDATORS_DIR" $"SECRETS_DIR"

# Switching to Nimbus folder
cd "${SRCDIR}"

# Setup Nimbus build system environment variables
source env.sh

build_once "nimbus_submodules" make update

PRESET_FILE="${SIM_ROOT}/${SPEC_VERSION}.yaml"
DEPOSITS_GENERATOR="${BUILD_DIR}/deposit_maker"

# Generate genesis file
$NIMBUS_BIN \
  --data-dir="${DATA_DIR}/nimbus" \
  createTestnet \
  --deposits-file=$DEPOSITS_DIR/deposits.json \
  --total-validators=$NUM_VALIDATORS \
  --output-genesis="${TESTNET_DIR}/genesis.ssz" \
  --output-bootstrap-file="${TESTNET_DIR}/bootstrap_nodes.txt" \
  --bootstrap-address=172.20.0.10 \
  --bootstrap-port=50000 \
  --genesis-offset=30 # Delay in seconds

echo "Genesis is ready!"

# do not use this, it's wrong
# will cause:
# got error on dial: failed to negotiate security protocol: peer id mismatch: expected 16Uiu2HAmULPTzyRTVh6zoW9KZ3zEYow1nfHMiZX6prihTudv2tKG, but remote key matches 16Uiu2HAmFoKBrhv5f3xF5V4LH91d4qLuJ89SJs5kyCA7ZUgDAVrM
rm -f "${TESTNET_DIR}/bootstrap_nodes.txt" 

echo 0 > $TESTNET_DIR/deposit_contract_block.txt
echo 0 > $TESTNET_DIR/deploy_block.txt
echo 0x0000000000000000000000000000000000000000 > $TESTNET_DIR/deposit_contract.txt
cp "${SIM_ROOT}/${SPEC_VERSION}.yaml" "$TESTNET_DIR/config.yaml"
