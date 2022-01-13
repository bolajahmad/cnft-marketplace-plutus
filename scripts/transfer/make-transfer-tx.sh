set -eux

thisDir=$(dirname "$0")
baseDir=$thisDir/..

sendingAddr=$1
receivingAddr=$2
tADAValue=$3

nftValidatorFile=$baseDir/auction.plutus
scriptHash=$(cat $baseDir/$BLOCKCHAIN_PREFIX/auction.addr)

$baseDir/hash-plutus.sh
extraOutput=""
if [ "$changeOutput" != "" ];then
  extraOutput="+ $changeOutput"
fi

cardano-cli transaction build-raw \
    --tx-in $senderAddr \
    --tx-out $(cat $HOME/testnet/$sendingAddr.addr)+0 \
    --tx-out $(cat $HOME/testnet/$receivingAddr.addr)+0 \
    --fee 0 \
    --out-file $HOME/testnet/transfer-tx.draft

echo "drafted transaction to $bodyFile"

cardano-cli transaction sign \
   --tx-body-file $bodyFile \
   --signing-key-file $signingKey \
   $BLOCKCHAIN \
   --out-file $outFile

echo "signed transaction and saved as $outFile"

cardano-cli transaction submit \
  $BLOCKCHAIN \
  --tx-file $outFile

echo "submitted transaction"

echo
