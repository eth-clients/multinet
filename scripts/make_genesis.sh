#!/bin/bash

GO_PATH=/root/multinet/go

NIMBUS_NODES=${NIMBUS_NODES:-1}
LIGHTHOUSE_NODES=${LIGHTHOUSE_NODES:-1}
PRYSM_NODES=${PRYSM_NODES:-1}

NIMBUS_DEV_NODES=${NIMBUS_DEV_NODES:-0}
LIGHTHOUSE_DEV_NODES=${LIGHTHOUSE_DEV_NODES:-0}
PRYSM_DEV_NODES=${PRYSM_DEV_NODES:-0}

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

for ((c=0; c<$NIMBUS_NODES; c++)) do
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
  --out-loc="/root/multinet/repo/deposits/nimbus-$c" \
  --source-mnemonic="$VALIDATORS_MNEMONIC" \
  --source-min=$VALIDATOR_OFFSET \
  --source-max=$(($VALIDATOR_OFFSET + $NIMBUS_VALIDATORS)) \
  --count=$NIMBUS_VALIDATORS \
  --config-base-path="/root/multinet/repo/deposits" \
  --key-man-loc="/root/multinet/repo/deposits/wallets" \
  --wallet-name="multinet-wallet"

mv /root/multinet/repo/deposits/nimbus-$c/nimbus-keys /root/multinet/repo/deposits/nimbus-$c/validators
chmod -R 750 /root/multinet/repo/deposits/nimbus-$c
chmod -R 600 /root/multinet/repo/deposits/nimbus-$c/validators
chmod -R 600 /root/multinet/repo/deposits/nimbus-$c/secrets

VALIDATOR_OFFSET=$(($VALIDATOR_OFFSET + $NIMBUS_VALIDATORS))
done

for ((c=0; c<$NIMBUS_DEV_NODES; c++)) do
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
  --out-loc="/root/multinet/repo/deposits/nimbus-dev-$c" \
  --source-mnemonic="$VALIDATORS_MNEMONIC" \
  --source-min=$VALIDATOR_OFFSET \
  --source-max=$(($VALIDATOR_OFFSET + $NIMBUS_VALIDATORS)) \
  --count=$NIMBUS_VALIDATORS \
  --config-base-path="/root/multinet/repo/deposits" \
  --key-man-loc="/root/multinet/repo/deposits/wallets" \
  --wallet-name="multinet-wallet"

mv /root/multinet/repo/deposits/nimbus-dev-$c/nimbus-keys /root/multinet/repo/deposits/nimbus-dev-$c/validators
chmod -R 750 /root/multinet/repo/deposits/nimbus-dev-$c
chmod -R 600 /root/multinet/repo/deposits/nimbus-dev-$c/validators
chmod -R 600 /root/multinet/repo/deposits/nimbus-dev-$c/secrets

VALIDATOR_OFFSET=$(($VALIDATOR_OFFSET + $NIMBUS_VALIDATORS))
done

# LH

for ((c=0; c<$LIGHTHOUSE_NODES; c++)) do
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
  --out-loc="/root/multinet/repo/deposits/lighthouse-$c" \
  --source-mnemonic="$VALIDATORS_MNEMONIC" \
  --source-min=$VALIDATOR_OFFSET \
  --source-max=$(($VALIDATOR_OFFSET + $LIGHTHOUSE_VALIDATORS)) \
  --count=$LIGHTHOUSE_VALIDATORS \
  --config-base-path="/root/multinet/repo/deposits" \
  --key-man-loc="/root/multinet/repo/deposits/wallets" \
  --wallet-name="multinet-wallet"

VALIDATOR_OFFSET=$(($VALIDATOR_OFFSET + $LIGHTHOUSE_VALIDATORS))
done

for ((c=0; c<$LIGHTHOUSE_DEV_NODES; c++)) do
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
  --out-loc="/root/multinet/repo/deposits/lighthouse-dev-$c" \
  --source-mnemonic="$VALIDATORS_MNEMONIC" \
  --source-min=$VALIDATOR_OFFSET \
  --source-max=$(($VALIDATOR_OFFSET + $LIGHTHOUSE_VALIDATORS)) \
  --count=$LIGHTHOUSE_VALIDATORS \
  --config-base-path="/root/multinet/repo/deposits" \
  --key-man-loc="/root/multinet/repo/deposits/wallets" \
  --wallet-name="multinet-wallet"

VALIDATOR_OFFSET=$(($VALIDATOR_OFFSET + $LIGHTHOUSE_VALIDATORS))
done

# Prysm

for ((c=0; c<$PRYSM_NODES; c++)) do
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
  --out-loc="/root/multinet/repo/deposits/prysm-$c" \
  --source-mnemonic="$VALIDATORS_MNEMONIC" \
  --source-min=$VALIDATOR_OFFSET \
  --source-max=$(($VALIDATOR_OFFSET + $PRYSM_VALIDATORS)) \
  --count=$PRYSM_VALIDATORS \
  --config-base-path="/root/multinet/repo/deposits" \
  --key-man-loc="/root/multinet/repo/deposits/prysm-$c/prysm/wallets" \
  --wallet-name="multinet-wallet"

VALIDATOR_OFFSET=$(($VALIDATOR_OFFSET + $PRYSM_VALIDATORS))
done

for ((c=0; c<$PRYSM_DEV_NODES; c++)) do
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
  --out-loc="/root/multinet/repo/deposits/prysm-dev-$c" \
  --source-mnemonic="$VALIDATORS_MNEMONIC" \
  --source-min=$VALIDATOR_OFFSET \
  --source-max=$(($VALIDATOR_OFFSET + $PRYSM_VALIDATORS)) \
  --count=$PRYSM_VALIDATORS \
  --config-base-path="/root/multinet/repo/deposits" \
  --key-man-loc="/root/multinet/repo/deposits/prysm-dev-$c/prysm/wallets" \
  --wallet-name="multinet-wallet"

VALIDATOR_OFFSET=$(($VALIDATOR_OFFSET + $PRYSM_VALIDATORS))
done

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
SRCDIR=${NIMBUS_PATH:-"nimbus-eth2"}
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

PRESET_FILE="${SIM_ROOT}/${SPEC_VERSION}.yaml"
DEPOSITS_GENERATOR="${BUILD_DIR}/deposit_maker"

IP_ADDRESS=172.20.0.10
if [ "$MULTINET_POD_IP" != "" ]; then
  IP_ADDRESS=$MULTINET_POD_IP;
fi

# Generate genesis file
$NIMBUS_BIN \
  --data-dir="${DATA_DIR}/nimbus" \
  createTestnet \
  --deposits-file=$DEPOSITS_DIR/deposits.json \
  --total-validators=$NUM_VALIDATORS \
  --output-genesis="${TESTNET_DIR}/genesis.ssz" \
  --output-bootstrap-file="${TESTNET_DIR}/bootstrap_nodes.txt" \
  --bootstrap-address=$IP_ADDRESS \
  --bootstrap-port=50000 \
  --genesis-offset=111 # Delay in seconds

echo "Genesis is ready!"

# do not use this, it's wrong
# will cause:
# got error on dial: failed to negotiate security protocol: peer id mismatch: expected 16Uiu2HAmULPTzyRTVh6zoW9KZ3zEYow1nfHMiZX6prihTudv2tKG, but remote key matches 16Uiu2HAmFoKBrhv5f3xF5V4LH91d4qLuJ89SJs5kyCA7ZUgDAVrM
rm -f "${TESTNET_DIR}/bootstrap_nodes.txt" 

echo 0 > $TESTNET_DIR/deposit_contract_block.txt
echo 0 > $TESTNET_DIR/deploy_block.txt
echo 0x0000000000000000000000000000000000000000 > $TESTNET_DIR/deposit_contract.txt
cp "${SIM_ROOT}/${SPEC_VERSION}.yaml" "$TESTNET_DIR/config.yaml"
