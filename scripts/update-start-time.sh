set -eux
thisDir=$(dirname "$0")
tempDir=$thisDir/../temp

nowSeconds=$(date +%s)
now=$(($nowSeconds*1000))
tokenName=$1
timestamp=$(($nowSeconds*1000+$2))
prefix=${3:-0}

mkdir -p $tempDir/$BLOCKCHAIN_PREFIX/datums/$prefix
mkdir -p $tempDir/$BLOCKCHAIN_PREFIX/redeemers

paymentPkh=$(cat $tempDir/$BLOCKCHAIN_PREFIX/pkhs/payment-pkh.txt)
marketplacePkh=$(cat $tempDir/$BLOCKCHAIN_PREFIX/pkhs/attacker-pkh.txt)
outliantPkh=$(cat $tempDir/$BLOCKCHAIN_PREFIX/pkhs/outliant-pkh.txt)
buyerPkh=$(cat $tempDir/$BLOCKCHAIN_PREFIX/pkhs/buyer-pkh.txt)
buyer1Pkh=$(cat $tempDir/$BLOCKCHAIN_PREFIX/pkhs/buyer1-pkh.txt)

cat << EOF > $tempDir/$BLOCKCHAIN_PREFIX/datums/$prefix/start.json

{
  "constructor": 0,
  "fields": [
    {
      "constructor": 0,
      "fields": [
        {
          "bytes": "$tokenName"
        },
        {
          "int": $timestamp
        },
        {
          "int": $now
        }
      ]
    }
  ]
}

EOF

cat << EOF > $tempDir/$BLOCKCHAIN_PREFIX/datums/$prefix/bid-1.json

{
  "constructor": 0,
  "fields": [
    {
      "constructor": 0,
      "fields": [
        {
          "bytes": "$tokenName"
        },
        {
          "int": $timestamp
        },
        {
          "int": $now
        }
      ]
    }
  ]
}

EOF

cat << EOF > $tempDir/$BLOCKCHAIN_PREFIX/datums/$prefix/payment-bid-1.json
{
  "constructor": 0,
  "fields": [
    {
      "constructor": 0,
      "fields": [
        {
          "bytes": "$tokenName"
        },
        {
          "int": $timestamp
        },
        {
          "int": $now
        }
      ]
    }
  ]
}

EOF

cat << EOF > $tempDir/$BLOCKCHAIN_PREFIX/datums/$prefix/bid-2.json
{
  "constructor": 0,
  "fields": [
    {
      "constructor": 0,
      "fields": [
        {
          "bytes": "$tokenName"
        },
        {
          "int": $timestamp
        },
        {
          "int": $now
        }
      ]
    }
  ]
}

EOF

cat << EOF > $tempDir/$BLOCKCHAIN_PREFIX/redeemers/bid-1.json

{
  "constructor": 0,
  "fields": [
    {
      "constructor": 0,
      "fields": [
        {
          "bytes": "$buyerPkh"
        },
        {
          "int": 10000000
        }
      ]
    }
  ]
}


EOF

cat << EOF > $tempDir/$BLOCKCHAIN_PREFIX/redeemers/bid-2.json

{
  "constructor": 0,
  "fields": [
    {
      "constructor": 0,
      "fields": [
        {
          "bytes": "$buyer1Pkh"
        },
        {
          "int": 30000000
        }
      ]
    }
  ]
}

EOF

cat << EOF > $tempDir/$BLOCKCHAIN_PREFIX/redeemers/close.json

{ "constructor":1, "fields": []}

EOF

cat << EOF > $tempDir/$BLOCKCHAIN_PREFIX/redeemers/payment-bid-1.json

{
  "constructor": 0,
  "fields": [
    {
      "constructor": 0,
      "fields": [
        {
          "bytes": "$paymentPkh"
        },
        {
          "int": 10000000
        }
      ]
    }
  ]
}


EOF


$thisDir/hash-datums.sh
