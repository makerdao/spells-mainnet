#!/usr/bin/env bash
set -e

if [[ -z "$1" ]]; then
  echo "You must provide a date (YYYY-MM-DD) option to name the directory"
else
  mkdir "./archive/$date-DssSpell"
  cp "./src/DssSpell.sol" "./archive/$date-DssSpell"
  cp "./src/DssSpell.t.sol" "./archive/$date-DssSpell"
  cp "./src/DssSpell.t.base.sol" "./archive/$date-DssSpell"
  echo "Spell, tests and base copied to archive directory $date-DssSpell"
fi
