#!/usr/bin/env bash
set -e

[[ "$1" == https://raw.githubusercontent.com/makerdao/community/*/governance/votes/*.md ]] || { echo "Please provide the correct exec copy link to hash (e.g. url=https://raw.githubusercontent.com/makerdao/community/<commit>/governance/votes/<file name>.md)"; exit 1; }

if [[ -x "$(command -v wget)" ]]; then
    cast keccak -- "$(wget "$1" -q -O - 2>/dev/null)"
elif [[ -x "$(command -v curl)" ]]; then
    cast keccak -- "$(curl "$1" -o - 2>/dev/null)"
else
    echo "Please install either wget or curl";
    exit 1;
fi
