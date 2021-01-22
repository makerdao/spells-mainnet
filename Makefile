all     :; SOLC_FLAGS="--optimize --optimize-runs=1" \
               dapp --use solc:0.6.11 build
clean   :; dapp clean
test    :; ./test-dssspell.sh
deploy  :; SOLC_FLAGS="--optimize --optimize-runs=1" \
    dapp --use solc:0.6.11 build && \
    dapp create DssSpell
flatten :; hevm flatten --source-file "src/DssSpell.sol" > out/flat.sol
