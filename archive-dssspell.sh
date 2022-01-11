#!/usr/bin/env bash
set -e

if [[ -z "$1" ]]; then
  echo "You must provide a date (YYYY-MM-DD) option to name the directory"
else
  rm -rf "./archive/$1-DssSpell"
  mkdir "./archive/$1-DssSpell"
  mkdir "./archive/$1-DssSpell/test"
  cp "./src/DssSpell.sol" "./archive/$1-DssSpell"
  cp "./src/DssSpellCollateralOnboarding.sol" "./archive/$1-DssSpell"
  cp "./src/DssSpell.t.sol" "./archive/$1-DssSpell"
  cp "./src/DssSpell.t.base.sol" "./archive/$1-DssSpell"
  cp ./src/test/* "./archive/$1-DssSpell/test"
  echo "Spell, tests and base copied to archive directory $1-DssSpell"
fi
