set -eu
thisDir=$(dirname "$0")

$thisDir/find-utxo.sh $(cat $thisDir/../$BLOCKCHAIN_PREFIX/auction.addr)
