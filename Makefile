all           :; DAPP_LIBRARIES=' lib/dss-exec-lib/src/DssExecLib.sol:DssExecLib:0xfD88CeE74f7D78697775aBDAE53f9Da1559728E4' \
              DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=1 \
              dapp --use solc:0.6.12 build
clean         :; dapp clean
              # Usage example: make test match=SpellIsCast
test          :; ./test-dssspell.sh $(match)
test-forge    :; ./test-dssspell-forge.sh $(match)
deploy        :; make && dapp create DssSpell | xargs ./verify.py DssSpell
estimate      :; ./estimate-deploy-gas.sh
flatten       :; hevm flatten --source-file "src/DssSpell.sol" > out/flat.sol
archive-spell :; ./archive-dssspell.sh $(date)
