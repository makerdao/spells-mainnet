all    :; SOLC_FLAGS="--optimize --optimize-runs=1" dapp --use solc:0.5.12 build --extract
clean  :; dapp clean
test   :; ./test-dssspell.sh
deploy :; SOLC_FLAGS="--optimize --optimize-runs=1" dapp --use solc:0.5.12 create DssSpell
