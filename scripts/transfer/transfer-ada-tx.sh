set -eux

thisDir=$(dirname "$0")
baseDir=$thisDir/../
tempDir=$baseDir/../temp

sender=$1
receiver=$2

$baseDir/transfer/make-transfer-tx.sh \
  $(cat ~/$BLOCKCHAIN_PREFIX/seller.addr) \
  ~/$BLOCKCHAIN_PREFIX/seller.skey \
  $(cat $tempDir/$BLOCKCHAIN_PREFIX/datums/$DATUM_PREFIX/start-hash.txt) \
  "1758582 lovelace + 1 d6cfdbedd242056674c0e51ead01785497e3a48afbbb146dc72ee1e2.627562626c6573"

cardano-cli transaction build-raw \                                                                                        
--tx-in 3823be1e3e0aeb4b6a9bc6a8cede698db6328701bb6f6712533ed490594e440d#0 \
--tx-out $(cat $HOME/testnet/buyer1.addr)+0 \       
--tx-out $(cat $HOME/testnet/marketplace.addr)+0 \ 
--fee 0 \          
--out-file $HOME/testnet/tx.draft