
# A NFT Auction Smart Contract

This repo contains the source for the Salty bubbles NFT auction smart contract. The plutus code for the smart contract is located in `src/SaltyBubbles.hs`.

An executable code for compiling the smart contract is also in `app/Main.hs`.

## Building

To compile the code to a Plutus smart contract, run:

``
cabal run
``

This will write a file to `scripts/auction.plutus`. This is the script and can be used to generate a script address.

## Creating the Script Address

After compiling the smart contract, it is necessary to make a script address.

First source either the environment variables needed. 

* For testnet
``
$ source scripts/envvars/testnet-env.envvars
``

The environment variable files set `CARDANO_NODE_SOCKET_PATH` to the path of the appropriate Daedalus socket file. It you run a `cardano-node` on your own you should set this environment variable to your socket file location after sourcing the environment variable file. if you're not sure where this is located, run;

``
ps -ef | grep cardano-node
``

and copy the node.socket path

Next, run:

```bash
scripts/hash-plutus.sh
```

This will make the files `$BLOCKCHAIN_PREFIX/auction.addr`.

## Example Transactions

Example transactions can be found in `scripts/core-tx`. The scripts are used by other scripts in `scripts/tx-path` which demonstrates how to start, bid and close the auction.

## Example Redeemers and Datums

Example redeemers are found in `scripts/$BLOCKCHAIN_PREFIX/redeemers` and example datums are found in `scripts/datums`.


## Full System Testing Prerequistes

Before testing you need to make sure you have `cardano-cli` installed and on your path, and it must be version 1.31.0 or greater. You will also need the json utility `jq` as well as `cardano-cli` helper `cardano-cli-balance-fixer` which can be downloaded here: https://github.com/Canonical-LLC/cardano-cli-balance-fixer. cardano-cli-balance-fixer offers utilities that allow handling of Values and utxos. 

## Init (only done once)

First create the wallets and get the protocol parameters and fund all wallets.

```
$ ./scripts/wallets/make-all-wallets.sh
$ ./scripts/query-protocol-parameters.sh
```

# Manual Testing

We will walk through the process of manually testing a start, bid, outbid and close flow. Make sure that all wallets are properly funded ( al least 15ADA on each)

After following the setup steps above, first make sure that the `~/$BLOCKCHAIN_PREFIX/seller.addr` has Ada.

Start by minting a token for the auction:

```bash
$ scripts/minting/mint-nft.sh
```

Wait for the next slot:

```bash
$ scripts/wait/until-next-block.sh
```

You can now view the minted token in the `seller`'s wallet:

```bash
$ scripts/query/payment.sh
```

Now start the auction by calling:
 
```bash
$ scripts/tx-path/lock-tx.sh $tokenName 432000000 0
```

This will create an auction that expires in 432,000 seconds (approx. 5 days). The `0` is namespace used for creating folders. 
pass the token name as $tokenName

Wait for the next slot:

```bash
$ scripts/wait/until-next-block.sh
```

You can now view the token at the smart contract address:

```bash
$ scripts/query/script.sh
```

Now create a bid:

```bash
$ scripts/happy-path/bid-1-tx.sh
```

Wait for the next slot, and query the script address

```bash
$ scripts/query/sc.sh
```

It should show the additional 10 Ada bid is now stored there.

Make sure that the `~/$BLOCKCHAIN_PREFIX/buyer1.addr` has over 33 Ada.

Now create a bid, that replaces the first bid:

```bash
$ scripts/happy-path/bid-2-tx.sh
```

Wait for the next slot, and query the script address

```bash
$ scripts/query/sc.sh
```

This should show the new bid's Ada.

Query the `buyer` address:

```bash
$ scripts/query/buyer.sh
```

This should show the old bid Ada has been returned.

At this wait for the auction to expire.

Make sure that the `~/$BLOCKCHAIN_PREFIX/marketplace.addr` has over 3 Ada.

When the time is right, call close:

```bash
$ scripts/happy-path/close-tx.sh
```

Wait for the next slot, and then check that the token is in `buyer1`'s wallet:

```bash
$ scripts/query/buyer-1.sh
```

and the bid is in the sellers wallet:

```bash
$ scripts/query/payment.sh
```

and the marketplace:

```bash
$ scripts/query/marketplace.sh
```
and

```bash
$ scripts/query/royalty.sh
```
