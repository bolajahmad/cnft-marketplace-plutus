{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE DeriveAnyClass             #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE NamedFieldPuns             #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE NoImplicitPrelude          #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE ScopedTypeVariables        #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE TypeApplications           #-}
{-# LANGUAGE TypeFamilies               #-}
{-# LANGUAGE BangPatterns               #-}

{-# LANGUAGE DerivingStrategies         #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE RecordWildCards            #-}
{-# LANGUAGE TypeOperators              #-}

module SaltyBubbles
  (
      auctionScript
    , auctionScriptShortBs
  ) where

import           Cardano.Api.Shelley  (PlutusScript (..), PlutusScriptV1)
import           Codec.Serialise
import qualified Data.ByteString.Lazy as LBS
import qualified Data.ByteString.Short as SBS
import           Data.Aeson           (ToJSON, FromJSON)
import           GHC.Generics         (Generic)
import qualified PlutusTx             as PlutusTx
import           PlutusTx.Prelude
import           Plutus.V1.Ledger.Credential
import qualified Plutus.V1.Ledger.Scripts as PlutusScripts
import           Ledger               hiding (singleton)
import qualified Ledger.Scripts       as Scripts
import qualified Ledger.Typed.Scripts as Scripts hiding (validatorHash)
import           Ledger.Value         as Value
import           Ledger.Ada           as Ada hiding (divide)
import           Prelude              (Show (..))

--------------------------------------------------------------------------------------------------
-- On Chain Code
--------------------------------------------------------------------------------------------------
data ContractInfo = ContractInfo
  { policyId             :: !CurrencySymbol
  , sellerAddress        :: !PubKeyHash
  , royalty1             :: !(PubKeyHash, Integer)
  , royalty2             :: !(PubKeyHash, Integer)
  , minPrice             :: !Integer
  }

contractInfo :: ContractInfo
contractInfo = ContractInfo 
  { policyId = "a0be1b06069518f7e1146fb2c98d78669e975d90182f01d91e2c5b31"
  , sellerAddress = "c6d60bd249a9e48f4d9e820751881887804343b4c02cdaaa5511f725"
  , royalty1 = ("af0d47ee09465e839be5ef78778ebe154711db448637db27df6912c2", 5000) -- 2.4% 1.6%
  , royalty2 = ("af0d47ee09465e839be5ef78778ebe154711db448637db27df6912c2", 5000) -- 0.4%
  , minPrice = 70000000
  }

PlutusTx.unstableMakeIsData ''ContractInfo
PlutusTx.makeLift ''ContractInfo


data TradeDetails = TradeDetails
  { tdToken              :: !TokenName
  , tdDeadline           :: !POSIXTime 
  , tdStartTime          :: !POSIXTime
  } deriving (Show, Generic, ToJSON, FromJSON)

instance Eq TradeDetails where
    {-# INLINABLE (==) #-}
    a == b
      =  (tdToken              a == tdToken                   b)
      && (tdDeadline           a == tdDeadline                b)
      && (tdStartTime          a == tdStartTime               b)

PlutusTx.unstableMakeIsData ''TradeDetails -- Make Stable when live
PlutusTx.makeLift ''TradeDetails

data OfferDetails = OfferDetails
    { tradeOwner       :: !PubKeyHash
    , requestedAmount    :: !Integer
    } deriving Show

instance Eq OfferDetails where
    {-# INLINABLE (==) #-}
    a == b
      =  (tradeOwner a == tradeOwner b)
      && (requestedAmount    a == requestedAmount    b)

PlutusTx.unstableMakeIsData ''OfferDetails -- Make Stable when live
PlutusTx.makeLift ''OfferDetails


data TradeDatum = TradeDatum
    { tdTrade :: !TradeDetails
    } deriving Show

instance Eq TradeDatum where
    {-# INLINABLE (==) #-}
    a == b
      =  (tdTrade a == tdTrade b)

PlutusTx.unstableMakeIsData ''TradeDatum -- Make Stable when live
PlutusTx.makeLift ''TradeDatum

data TradeRedeemer = Buy OfferDetails | Close
    deriving Show

PlutusTx.unstableMakeIsData ''TradeRedeemer -- Make Stable when live
PlutusTx.makeLift ''TradeRedeemer

data Auctioning
instance Scripts.ValidatorTypes Auctioning where
    type instance DatumType Auctioning = TradeDatum
    type instance RedeemerType Auctioning = TradeRedeemer

-- Returns an Integer whose value is 'percent' percent greater than input (rounded down)
{-# INLINABLE increasePercent #-}
increasePercent :: Integer -> Integer -> Integer
increasePercent input percent = (input * (100 + percent)) `divide` 100

{-# INLINABLE lovelaces #-}
lovelaces :: Value -> Integer
lovelaces = Ada.getLovelace . Ada.fromValue

{-# INLINABLE lovelacesPaidTo #-}
lovelacesPaidTo :: TxInfo -> PubKeyHash -> Integer
lovelacesPaidTo info pkh = lovelaces (valuePaidTo info pkh)


-------------------------------------------------------------------------------
-- Payout Utilities
-------------------------------------------------------------------------------
type Percent = Integer
type Lovelaces = Integer

{-# INLINABLE minAda #-}
minAda :: Lovelaces
minAda = 1_000_000

{-# INLINABLE applyPercent #-}
applyPercent :: Integer -> Lovelaces -> Percent -> Lovelaces
applyPercent divider inVal pct = (inVal * pct) `divide` divider

{-# INLINABLE payoutIsValid #-}
payoutIsValid :: ContractInfo -> Lovelaces -> TxInfo -> Bool
payoutIsValid info total txInfo =
  let 
    outliantAmount = max minAda ((total * (snd $ royalty1 info)) `divide` 100)
    charityAmount = max minAda ((total * (snd $ royalty2 info)) `divide` 100)
    sellerAmount = total - outliantAmount - charityAmount

  in traceIfFalse "royalties not paid"
    (
      lovelacesPaidTo txInfo (fst $ royalty1 info) >= charityAmount 
        && lovelacesPaidTo txInfo (fst $ royalty2 info) >= outliantAmount
    )
    && traceIfFalse "seller not paid"
      (lovelacesPaidTo txInfo (sellerAddress info) >= sellerAmount)

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
{-# INLINABLE isScriptAddress #-}
isScriptAddress :: Address -> Bool
isScriptAddress Address { addressCredential } = case addressCredential of
  ScriptCredential _ -> True
  _ -> False

-- Verify that there is only one script input and get it's value.
{-# INLINABLE getOnlyScriptInput #-}
getOnlyScriptInput :: TxInfo -> Value
getOnlyScriptInput info =
  let
    isScriptInput :: TxInInfo -> Bool
    isScriptInput = isScriptAddress . txOutAddress . txInInfoResolved

    input = case filter isScriptInput . txInfoInputs $ info of
      [i] -> i
      _ -> traceError "expected exactly one script input"

  in txOutValue . txInInfoResolved $ input

{-# INLINABLE mkAuctionValidator #-}
mkAuctionValidator :: ContractInfo -> TradeDatum -> TradeRedeemer -> ScriptContext -> Bool
mkAuctionValidator cInfo datum redeemer ctx =
  -- Always perform the input check
  traceIfFalse "wrong input value" correctInputValue
    && case redeemer of
        Buy OfferDetails{..} -> 
          traceIfFalse "minimum price not met" (sufficientBid requestedAmount)
            && traceIfFalse "too late" correctSlotRange
            && traceIfFalse "expect buyer to get value" (getsValue tradeOwner tokenValue)
              && payoutIsValid cInfo requestedAmount info

          where
            -- Verify that the offer amount is greater than the minimum price
            sufficientBid :: Integer -> Bool
            sufficientBid amount = amount > (minPrice cInfo)

            -- Buying is allowed until the deadline
            correctSlotRange :: Bool
            !correctSlotRange
              =  (tdDeadline $ tdTrade datum) `after` txInfoValidRange info
        Close ->
          let
            -- Closing is allowed if the deadline is before than the valid tx
            -- range. The deadline is past.
            correctCloseSlotRange :: Bool
            !correctCloseSlotRange = (tdDeadline $ tdTrade datum) `before` txInfoValidRange info

            in traceIfFalse "too early" correctCloseSlotRange
            &&traceIfFalse
                      "expected seller to get token"
                      (getsValue (sellerAddress cInfo) tokenValue)

    where
    --    --------------------------------------------------------------------------------------------------
    --    -- Helper Functions
    --    --------------------------------------------------------------------------------------------------
        info :: TxInfo
        info = scriptContextTxInfo ctx

        -- The asset we are auctioning as a Value
        tokenValue :: Value
        tokenValue = Value.singleton (policyId cInfo) (tdToken $ tdTrade datum) 1

        -- The value we expect on the script input based on
        -- datum.
        expectedScriptValue :: Integer -> Value
        expectedScriptValue val = tokenValue <> Ada.lovelaceValueOf val

        actualScriptValue :: Value
        !actualScriptValue = getOnlyScriptInput info
        -- Ensure the value is on the script address and there is
        -- only one script input.
        correctInputValue :: Bool
        !correctInputValue = case redeemer of 
          (Buy OfferDetails{..}) -> 
            actualScriptValue `Value.geq` expectedScriptValue requestedAmount
          (Close) -> False

        -- Helper to make sure the pkh is paid at least the value.
        getsValue :: PubKeyHash -> Value -> Bool
        getsValue h v = valuePaidTo info h `Value.geq` v


auctionTypedValidator :: Scripts.TypedValidator Auctioning
auctionTypedValidator = Scripts.mkTypedValidator @Auctioning
    ($$(PlutusTx.compile [|| mkAuctionValidator ||]) `PlutusTx.applyCode` PlutusTx.liftCode contractInfo)
    $$(PlutusTx.compile [|| wrap ||])
  where
    wrap = Scripts.wrapValidator @TradeDatum @TradeRedeemer

auctionValidator :: Validator
auctionValidator = Scripts.validatorScript auctionTypedValidator

auctionAddress :: Ledger.ValidatorHash
auctionAddress = Scripts.validatorHash auctionValidator

script :: PlutusScripts.Script
script = PlutusScripts.unValidatorScript auctionValidator

auctionScriptShortBs :: SBS.ShortByteString
auctionScriptShortBs = SBS.toShort . LBS.toStrict $ serialise script

auctionScript :: PlutusScript PlutusScriptV1
auctionScript = PlutusScriptSerialised auctionScriptShortBs
