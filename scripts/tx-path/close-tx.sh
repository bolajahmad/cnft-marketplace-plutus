set -eu
thisDir=$(dirname "$0")
baseDir=$thisDir/../
tempDir=$baseDir/../temp

DATUM_PREFIX=${DATUM_PREFIX:-0}

$baseDir/core-tx/close-successfully-tx.sh \
  $(cat ~/$BLOCKCHAIN_PREFIX/seller.addr) \
  ~/$BLOCKCHAIN_PREFIX/marketplace.skey \
  "d6cfdbedd242056674c0e51ead01785497e3a48afbbb146dc72ee1e2.627562626c6573" \
  $tempDir/$BLOCKCHAIN_PREFIX/datums/$DATUM_PREFIX/bid-2.json \
  $(cat $tempDir/$BLOCKCHAIN_PREFIX/datums/$DATUM_PREFIX/bid-2-hash.txt) \
  $(cat ~/$BLOCKCHAIN_PREFIX/buyer1.addr) \
  27000000 \
  $(cat ~/$BLOCKCHAIN_PREFIX/seller.addr) \
  3000000 \
  $(cat ~/$BLOCKCHAIN_PREFIX/marketplace.addr)
