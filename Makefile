all    :; SOLC_FLAGS="--optimize --optimize-runs=1" dapp --use solc:0.5.12 build
clean  :; dapp clean
test   :; ./test-dssspell.sh
