set -eux

mkdir -p scripts/temp/
mkdir -p ~/$BLOCKCHAIN_PREFIX

./scripts/wallets/make-wallet-and-pkh.sh buyer
./scripts/wallets/make-wallet-and-pkh.sh buyer1
./scripts/wallets/make-wallet-and-pkh.sh outliant
./scripts/wallets/make-wallet-and-pkh.sh attacker
