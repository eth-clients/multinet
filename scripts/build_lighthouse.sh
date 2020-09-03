#!/bin/bash

# https://github.com/sigp/lighthouse/blob/master/docs/interop.md

export RUST_LOG=trace,libp2p=trace,multistream=trace,gossipsub=trace

set -eu

# Read in variables
cd "$(dirname "$0")"
source vars.sh

SRCDIR=${LIGHTHOUSE_PATH:-"lighthouse"}

# Make sure you also have the development packages of openssl installed.
# For example, `libssl-dev` on Ubuntu or `openssl-devel` on Fedora.

echo Locating protoc...
if ! command -v protoc; then
  MSG="protoc (the Google Protobuf compiler) is missing. Please install it manually"
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    MSG+=" with sudo apt install protobuf-compiler"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    MSG+=" with 'brew install protobuf'"
  elif [[ "$OSTYPE" == "cygwin" ]]; then
    # POSIX compatibility layer and Linux environment emulation for Windows
    MSG+=""
  elif [[ "$OSTYPE" == "msys" ]]; then
    # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
    MSG+=""
  elif [[ "$OSTYPE" == "win32" ]]; then
    # I'm not sure this can happen.
    MSG+=""
  elif [[ "$OSTYPE" == "freebsd"* ]]; then
    # ...
    MSG+=""
  else
    # Unknown.
    MSG+=""
  fi
  echo $MSG
  exit 1
fi

command -v cargo > /dev/null || { echo "install rust first (https://rust-lang.org)"; exit 1; }

[[ -d "$SRCDIR" ]] || {
  git clone -b master https://github.com/sigp/lighthouse.git "$SRCDIR"
}

pushd "$SRCDIR"
cargo build --release --bin lighthouse
popd
