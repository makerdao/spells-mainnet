#!/usr/bin/env bash
#
# pass in PIP as an argument

export OSM=$1

rawStorage=$(cast storage "$OSM" 6)
nextPrice=$(cast --from-wei "$(cast --to-dec "${rawStorage:34:32}")")
rawStorage=$(cast storage "$OSM" 7)
currentPrice=$(cast --from-wei "$(cast --to-dec "${rawStorage:34:32}")")
hazPoke=$(cast call "$OSM" 'pass()(bool)')

echo "canPoke: ${hazPoke}"
echo "next price: ${currentPrice}"
echo "this price: ${nextPrice}"
