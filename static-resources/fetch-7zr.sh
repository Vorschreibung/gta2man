#!/usr/bin/env bash
set -eo pipefail

# cd to parent dir of current script
cd "$(dirname "${BASH_SOURCE[0]}")"

# fetch if need be
if [[ ! -f ./7zr.exe ]]; then
    wget "https://www.7-zip.org/a/7zr.exe"
fi

# verify sha256sum, if it fails remove file immediately
actual_sha256=$(sha256sum "./7zr.exe")
expected_sha256="5e47d0900fb0ab13059e0642c1fff974c8340c0029decc3ce7470f9aa78869ab  ./7zr.exe"
if [[ "$actual_sha256" != "$expected_sha256" ]]; then
    echo "actual_sha256 '$actual_sha256' != expected_sha256 '$expected_sha256'"
    rm "./7zr.exe"
    exit 1
fi

chmod +x ./7zr.exe
