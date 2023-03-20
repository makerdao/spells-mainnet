#!/usr/bin/env bash

### rates -- list all rates or compute specific ones
### Usage:
### ./rates.sh list all rates from 0 to 100% with granularity of 0.01%
### ./rates.sh <entry> return the computed rate

set -e

rate() {
    basispoints=$(printf "%.0f" "$(echo "scale=0; $1*100" | bc)")
    normalizedamount="$(echo "scale=4; $basispoints/10000 + 1" | bc)"
    rayte=$(bc -l <<< "scale=27; e( l($normalizedamount)/(60 * 60 * 24 * 365) ) * 10^27")
    echo "$1%: ${rayte%.*}"
}

if [[ -z $1 ]]; then
    for n in $(seq 0 0.01 100);
    do
        rate "$n"
    done
elif [[ $1 =~ ^([1-9][0-9]*|[0-9])(\.[0-9]+)?$ ]]; then
    rate "$1"
else
    echo "Please specify a percentage parameter (e.g. for 4.25% use $0 4.25 or make rates pct=4.25)"
    exit 1
fi
