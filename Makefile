all     :; DAPP_LIBRARIES=' lib/dss-exec-lib/src/DssExecLib.sol:DssExecLib:0x9a6c490bA30507E732D61235eFF94c26AEa234EF' \
           DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=1 \
           dapp --use solc:0.6.11 build
clean   :; dapp clean
           # Usage example: make test match=SpellIsCast
test    :; ./test-dssspell.sh $(match)
deploy  :; make && dapp create DssSpell
estimate:; ./estimate-deploy-gas.sh
flatten :; hevm flatten --source-file "src/DssSpell.sol" > out/flat.sol
