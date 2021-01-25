all     :; DAPP_BUILD_OPTIMIZE="1" SOLC_FLAGS="--optimize" \
               dapp --use solc:0.6.11 build
clean   :; dapp clean
test    :; ./test-dssspell.sh
deploy  :; DAPP_BUILD_OPTIMIZE="1" SOLC_FLAGS="--optimize" \
    dapp --use solc:0.6.11 build && \
    dapp create DssSpell
flatten :; hevm flatten --source-file "src/DssSpell.sol" > out/flat.sol
