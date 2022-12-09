#!/usr/bin/env bash
#
# pass in PIP as an argument

export OSM=$1

rawStorage=$(seth storage "$OSM" 3)
nextPrice=$(seth --from-wei "$(seth --to-dec "${rawStorage:34:32}")")
rawStorage=$(seth storage "$OSM" 4)
currentPrice=$(seth --from-wei "$(seth --to-dec "${rawStorage:34:32}")")
hazPoke=$(seth call "$OSM" 'pass()(bool)')

echo "canPoke: ${hazPoke}"
echo "next price: ${currentPrice}"
echo "this price: ${nextPrice}"
