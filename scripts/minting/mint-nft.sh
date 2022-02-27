set -eux

tokenName=$1
realTokenName=$(echo -n $tokenName | xxd -b -ps -c 80 | tr -d '\n')
policyScript=~/cnft/policy/policy.script
policyid=$(cat ~/cnft/policy/policyid)
metadata=$2

./scripts/minting/test-mint-tx.sh \
  $(cardano-cli-balance-fixer collateral --address $(cat ~/cnft/keys/payment.addr) $BLOCKCHAIN) \
   $policyScript \
   $policyid \
   $realTokenName \
   1 \
   ~/cnft/metadata/$metadata.json 
 