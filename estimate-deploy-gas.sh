#!/usr/bin/env bash

BIN=$(jq '.contracts|.["src/DssSpell.sol:DssSpell"]|.bin' ./out/dapp.sol.json | sed 's/"//g')
seth estimate --create "0x${BIN}" "DssSpell()"
