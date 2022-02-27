set -eu
thisDir=$(dirname "$0")
$thisDir/find-utxo.sh $(cat ~/cnft/keys/payment.addr)
