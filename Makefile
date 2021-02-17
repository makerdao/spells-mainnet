all     :;  DAPP_LIBRARIES=' lib/dss-exec-lib/src/DssAction.sol:DssExecLib:0x25dA9Fce914fa6914631add105d83691E19e23a3' \
            DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=1 \
            dapp --use solc:0.6.11 build
clean   :; dapp clean
           # Usage example: make test match=SpellIsCast
test    :; ./test-dssspell.sh $(match)
deploy  :; make && dapp create DssSpell
estimate:; ./estimate-deploy-gas.sh
flatten :; hevm flatten --source-file "src/DssSpell.sol" > out/flat.sol
