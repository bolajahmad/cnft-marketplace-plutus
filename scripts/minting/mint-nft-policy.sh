./scripts/minting/test-mint-tx.sh \
  $(cardano-cli-balance-fixer collateral --address $(cat ~/$BLOCKCHAIN_PREFIX/seller.addr) $BLOCKCHAIN) \
   scripts/nft-policies/nft-policy-0.plutus \
   $(cat scripts/nft-policies/nft-policy-0-id.txt) 627562626c6573 1
