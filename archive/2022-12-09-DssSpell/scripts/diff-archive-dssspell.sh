#!/usr/bin/env bash
set -e

if [[ -z "$1" ]]; then
  echo "You must provide a date (YYYY-MM-DD) option to diff the directory"
else
  diff -r "./src" "./archive/$1-DssSpell"
  echo "Spell, tests and base match the archive directory $1-DssSpell"
fi
