#!/usr/bin/env bash
#
# pass in PIP as an argument

export OSM=$1

rawStorage=$(cast storage "$OSM" 3)
nextPrice=$(cast --from-wei "$(cast --to-dec "${rawStorage:34:32}")")
rawStorage=$(cast storage "$OSM" 4)
currentPrice=$(cast --from-wei "$(cast --to-dec "${rawStorage:34:32}")")
hazPoke=$(cast call "$OSM" 'pass()(bool)')

echo "canPoke: ${hazPoke}"
echo "next price: ${currentPrice}"
echo "this price: ${nextPrice}"
