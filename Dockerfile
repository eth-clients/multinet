FROM ubuntu:20.04 as multinet-tools

ENV DEBIAN_FRONTEND=noninteractive
RUN apt -y update
RUN apt -y install tzdata
RUN apt -y install build-essential git protobuf-compiler golang python3 cmake wget curl gnupg jq

RUN curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > bazel.gpg
RUN mv bazel.gpg /etc/apt/trusted.gpg.d/
RUN echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list
RUN apt -y update && apt -y install bazel bazel-3.2.0

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

WORKDIR /root/multinet/repo
ENV HOME=/root/multinet

WORKDIR /root/multinet

ENV ETH2_TOOLS_COMMIT b1d4db5ef0fbee2cd6e132c04a6f9b8890043cc7
RUN git clone https://github.com/protolambda/eth2-val-tools.git 
WORKDIR /root/multinet/eth2-val-tools

RUN git checkout ${ETH2_TOOLS_COMMIT}

RUN go install . && \
cd .. && \
GO111MODULE=on go get github.com/wealdtech/ethereal

WORKDIR /root/multinet

COPY ./scripts/vars.sh /root/multinet/repo
RUN wget -O /root/multinet/repo/mainnet.yaml https://raw.githubusercontent.com/ethereum/eth2.0-specs/v0.12.3/configs/mainnet/phase0.yaml
RUN wget -O /root/multinet/repo/minimal.yaml https://raw.githubusercontent.com/ethereum/eth2.0-specs/v0.12.3/configs/minimal/phase0.yaml

WORKDIR /root/multinet/repo

FROM multinet-tools as multinet-nimbus

COPY ./scripts/build_genesis.sh /root/multinet/repo
RUN ["/bin/bash", "build_genesis.sh"]

COPY ./scripts/build_nimbus.sh /root/multinet/repo
RUN ["/bin/bash", "build_nimbus.sh"]

COPY ./scripts/run_nimbus.sh /root/multinet/repo
RUN chmod +x /root/multinet/repo/run_nimbus.sh

COPY ./scripts/make_genesis.sh /root/multinet/repo
RUN chmod +x /root/multinet/repo/make_genesis.sh

COPY ./scripts/wait_for.sh /root/multinet/repo
RUN chmod +x /root/multinet/repo/wait_for.sh

FROM multinet-tools as multinet-lighthouse

COPY ./scripts/build_lighthouse.sh /root/multinet/repo
RUN ["/bin/bash", "build_lighthouse.sh"]
COPY ./scripts/run_lighthouse.sh /root/multinet/repo
RUN chmod +x /root/multinet/repo/run_lighthouse.sh

COPY ./scripts/wait_for.sh /root/multinet/repo
RUN chmod +x /root/multinet/repo/wait_for.sh

FROM multinet-tools as multinet-prysm

COPY ./scripts/build_prysm.sh /root/multinet/repo
RUN ["/bin/bash", "build_prysm.sh"]
COPY ./scripts/run_prysm.sh /root/multinet/repo
RUN chmod +x /root/multinet/repo/run_prysm.sh

COPY ./scripts/wait_for.sh /root/multinet/repo
RUN chmod +x /root/multinet/repo/wait_for.sh
