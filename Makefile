clean                :; forge clean
                        # Usage example: make test match=SpellIsCast
test                 :; ./scripts/test-dssspell-forge.sh no-match="$(no-match)" match="$(match)" block="$(block)"
test-forge           :; ./scripts/test-dssspell-forge.sh no-match="$(no-match)" match="$(match)" block="$(block)"
estimate             :; ./scripts/estimate-deploy-gas.sh
deploy               :; ./scripts/deploy.py
deploy-info          :; ./scripts/get-deploy-info.sh tx=$(tx)
verify               :; ./scripts/verify.py DssSpell $(addr)
flatten              :; forge flatten src/DssSpell.sol --output out/flat.sol
diff-deployed-spell  :; ./scripts/diff-deployed-dssspell.sh $(spell)
check-deployed-spell :; ./scripts/check-deployed-dssspell.sh
cast-on-tenderly     :; cd ./scripts/cast-on-tenderly/ && npm i && npm start -- $(spell); cd -
archive-spell        :; ./scripts/archive-dssspell.sh "$(if $(date),$(date),$(shell date +'%Y-%m-%d'))"
diff-archive-spell   :; ./scripts/diff-archive-dssspell.sh "$(if $(date),$(date),$(shell date +'%Y-%m-%d'))"
feed                 :; ./scripts/check-oracle-feed.sh $(pip)
feed-lp              :; ./scripts/check-oracle-feed-lp.sh $(pip)
wards                :; ./scripts/wards.sh $(target)
time                 :; ./scripts/time.py date="$(date)" stamp="$(stamp)"
exec-hash            :; ./scripts/hash-exec-copy.py date="$(date)"
opt-cost             :; ./scripts/get-opt-relay-cost.sh $(spell)
arb-cost             :; ./scripts/get-arb-relay-cost.sh $(spell)
rates                :; ./scripts/rates.sh $(pct)
