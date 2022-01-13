set -eux
thisDir=$(dirname "$0")
baseDir=$thisDir/../
tempDir=$baseDir/../temp

DATUM_PREFIX=${DATUM_PREFIX:-0}

$baseDir/core-tx/bid-tx.sh \
  $(cat ~/$BLOCKCHAIN_PREFIX/buyer.addr) \
  ~/$BLOCKCHAIN_PREFIX/buyer.skey \
  d6cfdbedd242056674c0e51ead01785497e3a48afbbb146dc72ee1e2.627562626c6573 \
  $tempDir/$BLOCKCHAIN_PREFIX/datums/$DATUM_PREFIX/start.json \
  $(cat $tempDir/$BLOCKCHAIN_PREFIX/datums/$DATUM_PREFIX/start-hash.txt) \
  $(cat $tempDir/$BLOCKCHAIN_PREFIX/datums/$DATUM_PREFIX/bid-1-hash.txt) \
  $tempDir/$BLOCKCHAIN_PREFIX/datums/$DATUM_PREFIX/bid-1.json \
  10000000 \
  $tempDir/$BLOCKCHAIN_PREFIX/redeemers/bid-1.json
