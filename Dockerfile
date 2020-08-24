FROM ubuntu:20.04 as tools

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update
RUN apt-get -y install tzdata
RUN apt-get -y install build-essential git protobuf-compiler golang

RUN apt install curl gnupg
RUN curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > bazel.gpg
RUN mv bazel.gpg /etc/apt/trusted.gpg.d/
RUN echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list
RUN apt -y update && apt -y install bazel bazel-3.2.0

RUN apt -y install wget

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH

RUN set -eux; \
    url="https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init"; \
    wget "$url"; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --default-toolchain stable; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

RUN rustup toolchain install nightly

RUN apt -y install redis-tools

WORKDIR /root/multinet/repo
ENV HOME=/root/multinet

FROM tools as deposits

WORKDIR /root/multinet

RUN git clone https://github.com/protolambda/eth2-val-tools.git 
WORKDIR /root/multinet/eth2-val-tools

RUN git checkout 437be13bbd37c5ea45ef6036586480b02ad09ac4

RUN go install . && \
cd .. && \
GO111MODULE=on go get github.com/wealdtech/ethereal

WORKDIR /root/multinet

ENV FORK_VERSION=0x00000000
ENV DEPOSIT_AMOUNT=32000000000
ENV WITHDRAWALS_MNEMONIC="enough animal salon barrel poet method husband evidence grain excuse grass science there wedding blind glimpse surge loan reopen chalk toward change survey bag"
ENV VALIDATORS_MNEMONIC="stay depend ignore lady access will dress idea hybrid tube original riot between plate ethics ecology green response hollow famous salute they warrior little"

RUN mkdir -p /root/multinet/repo/deposits

RUN go/bin/eth2-val-tools deposit-data \
--source-min=0 \
--source-max=32 \
--amount="$DEPOSIT_AMOUNT" \
--fork-version="$FORK_VERSION" \
--withdrawals-mnemonic="$WITHDRAWALS_MNEMONIC" \
--validators-mnemonic="$VALIDATORS_MNEMONIC" > /root/multinet/repo/deposits/assignments.json 2>&1

RUN go/bin/eth2-val-tools assign \
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

RUN mv /root/multinet/repo/deposits/nimbus/nimbus-keys /root/multinet/repo/deposits/nimbus/validators

RUN go/bin/eth2-val-tools deposit-data \
--source-min=32 \
--source-max=64 \
--amount="$DEPOSIT_AMOUNT" \
--fork-version="$FORK_VERSION" \
--withdrawals-mnemonic="$WITHDRAWALS_MNEMONIC" \
--validators-mnemonic="$VALIDATORS_MNEMONIC" > /root/multinet/repo/deposits/assignments.json 2>&1

RUN go/bin/eth2-val-tools assign \
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

RUN go/bin/eth2-val-tools deposit-data \
--source-min=64 \
--source-max=96 \
--amount="$DEPOSIT_AMOUNT" \
--fork-version="$FORK_VERSION" \
--withdrawals-mnemonic="$WITHDRAWALS_MNEMONIC" \
--validators-mnemonic="$VALIDATORS_MNEMONIC" > /root/multinet/repo/deposits/assignments.json 2>&1

RUN go/bin/eth2-val-tools assign \
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

FROM tools as genesis

COPY ./.git /root/multinet/repo/.git
COPY ./vars.sh /root/multinet/repo
COPY ./mainnet.yaml /root/multinet/repo

COPY ./build_genesis.sh /root/multinet/repo
RUN ["/bin/bash", "build_genesis.sh"]

FROM genesis as nimbus

COPY ./build_nimbus.sh /root/multinet/repo
RUN ["/bin/bash", "build_nimbus.sh"]

COPY ./run_nimbus.sh /root/multinet/repo
RUN chmod +x /root/multinet/repo/run_nimbus.sh

COPY ./make_genesis.sh /root/multinet/repo
RUN chmod +x /root/multinet/repo/make_genesis.sh

COPY ./wait_for.sh /root/multinet/repo

FROM genesis as lighthouse

RUN apt -y install cmake

COPY ./build_lighthouse.sh /root/multinet/repo
RUN ["/bin/bash", "build_lighthouse.sh"]
COPY ./run_lighthouse.sh /root/multinet/repo

COPY ./wait_for.sh /root/multinet/repo

FROM genesis as prysm

RUN apt -y install python3

COPY ./build_prysm.sh /root/multinet/repo
RUN ["/bin/bash", "build_prysm.sh"]
COPY ./run_prysm.sh /root/multinet/repo

COPY ./wait_for.sh /root/multinet/repo
