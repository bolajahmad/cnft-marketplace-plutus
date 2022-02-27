set -eux

cardano-cli query utxo --address $1 $BLOCKCHAIN
