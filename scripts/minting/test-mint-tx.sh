set -eux

mkdir -p temp

utxo=$1
policyScript=$2
policyId=$3
tokenName=$4
mintCount=$5
metadata=$6
address=$(cat ~/cnft/keys/payment.addr)
holderAddress=$(cat ~/cnft/keys/payment.addr)

cardano-cli transaction build \
  --alonzo-era \
  $BLOCKCHAIN \
  --tx-in $utxo \
  --tx-in-collateral $utxo \
  --tx-out "$holderAddress + 1758582 lovelace + $mintCount $policyId.$tokenName" \
  --mint="$mintCount $policyId.$tokenName" \
  --mint-script-file $policyScript \
  --change-address $address \
  --invalid-hereafter 52922965 \
  --metadata-json-file $metadata \
  --protocol-params-file ~/cnft/protocol-params.json \
  --out-file temp/mint_tx.body

cardano-cli transaction sign  \
  --signing-key-file ~/cnft/keys/payment.skey  \
  --signing-key-file ~/cnft/policy/policy.skey \
  $BLOCKCHAIN \
  --tx-body-file temp/mint_tx.body \
  --out-file temp/mint_tx.signed

cardano-cli transaction submit --tx-file temp/mint_tx.signed $BLOCKCHAIN
