set -eux
thisDir=$(dirname "$0")
baseDir=$thisDir/../
tempDir=$baseDir/../temp

tokenName=$(echo -n $1 | xxd -b -ps -c 80 | tr -d '\n')
DATUM_PREFIX=${3:-0}

$baseDir/update-start-time.sh $tokenName $2 $DATUM_PREFIX

sleep 2

$baseDir/core-tx/lock-tx.sh \
  $(cat ~/cnft/keys/payment.addr) \
  ~/cnft/keys/payment.skey \
  $tempDir/$BLOCKCHAIN_PREFIX/datums/$DATUM_PREFIX/start.json \
  $tokenName
