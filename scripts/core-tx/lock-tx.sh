set -eux



thisDir=$(dirname "$0")
baseDir=$thisDir/../
tempDir=$baseDir/../temp

mkdir -p $tempDir
$baseDir/hash-plutus.sh
$baseDir/hash-datums.sh

# nftValidatorFile=$baseDir/auction.plutus
sellerAddress=$1
signingKey=$2
scriptDatumHash=$3
tokenName=$4
scriptHash=$(cat $baseDir/$BLOCKCHAIN_PREFIX/auction.addr)
policyid=$(cat ~/cnft/policy/policyid)
output="2000000 lovelace + 1 $policyid.$tokenName"

bodyFile=$tempDir/sell-tx-body.01
outFile=$tempDir/sell-tx.01
changeOutput=$(cardano-cli-balance-fixer change --address $sellerAddress $BLOCKCHAIN -o "$output")

extraOutput=""
if [ "$changeOutput" != "" ];then
  extraOutput="+ $changeOutput"
fi

cardano-cli transaction build \
    --alonzo-era \
    $BLOCKCHAIN \
    $(cardano-cli-balance-fixer input --address $sellerAddress $BLOCKCHAIN) \
    --tx-out "$scriptHash + $output" \
    --tx-out-datum-hash-file $scriptDatumHash \
    --tx-out "$sellerAddress + 2000000 lovelace $extraOutput" \
    --change-address $sellerAddress \
    --protocol-params-file ~/cnft/protocol-params.json \
    --out-file $bodyFile

echo "saved transaction to $bodyFile"

cardano-cli transaction sign \
    --tx-body-file $bodyFile \
    --signing-key-file $signingKey \
    --signing-key-file ~/cnft/policy/policy.skey \
    $BLOCKCHAIN \
    --out-file $outFile

echo "signed transaction and saved as $outFile"

cardano-cli transaction submit \
 $BLOCKCHAIN \
 --tx-file $outFile

echo "submitted transaction"

echo
