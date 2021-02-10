all     :; DAPP_SOLC_OPTIMIZE=true DAPP_SOLC_OPTIMIZE_RUNS=1 SOLC_FLAGS="--optimize --optimize-runs=1" \
               dapp --use solc:0.6.11 build
clean   :; dapp clean
           # Usage example: make test match=SpellIsCast
test    :; ./test-dssspell.sh $(match)
deploy  :; make && dapp create DssSpell
flatten :; hevm flatten --source-file "src/DssSpell.sol" > out/flat.sol
