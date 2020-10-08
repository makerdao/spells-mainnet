all    :; SOLC_FLAGS="--optimize --optimize-runs=1" \
		dapp --use solc:0.5.12 build
clean  :; dapp clean
test   :; ./test-dssspell.sh
deploy :; SOLC_FLAGS="--optimize --optimize-runs=1" \
    dapp --use solc:0.5.12 build && \
    dapp create DssSpell --gas=${ETH_GAS} --gas-price=${ETH_GAS_PRICE}
