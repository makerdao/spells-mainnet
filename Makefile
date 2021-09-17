all     :; DAPP_LIBRARIES=' lib/dss-exec-lib/src/DssExecLib.sol:DssExecLib:0xfd88cee74f7d78697775abdae53f9da1559728e4' \
           DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=1 \
           dapp --use solc:0.6.12 build
clean   :; dapp clean
           # Usage example: make test match=SpellIsCast
test    :; ./test-dssspell.sh $(match)
deploy  :; make && dapp create DssSpell
estimate:; ./estimate-deploy-gas.sh
flatten :; hevm flatten --source-file "src/DssSpell.sol" > out/flat.sol
