{-# LANGUAGE GADTs      #-}
{-# LANGUAGE LambdaCase #-}

-- | An HTTP client for working with the wallet interaction API. For use with 'Wallet.Emulator.Http'.
module Wallet.Emulator.Client
  ( Environment(Environment)
  , WalletClient
  , runWalletClient
  , wallets
  , fetchWallet
  , createWallet
  , getTransactions
  , blockValidated
  , slot
  , processPending
  , assertOwnFundsEq
  , assertIsValidated
  , process
  ) where

import           Control.Monad              (void)
import           Control.Monad.Except       (ExceptT (ExceptT), throwError)
import           Control.Monad.Operational  (interpretWithMonad)
import           Control.Monad.Reader       (MonadReader, ReaderT, asks, lift, runReaderT)
import           Control.Monad.Writer       (MonadWriter, WriterT, runWriterT, tell)
import           Data.Foldable              (fold)
import           Data.Proxy                 (Proxy (Proxy))
import           Data.Set                   (Set)
import           Ledger                     (Address, Block, Slot, Tx, TxIn, TxOut, Value)
import           Servant.API                ((:<|>) ((:<|>)), NoContent)
import           Servant.Client             (ClientEnv, ClientM, ServantError, client, runClientM)
import           Wallet.API                 (KeyPair, WalletAPI (..))
import           Wallet.Emulator.AddressMap (AddressMap)
import           Wallet.Emulator.Http       (API)
import           Wallet.Emulator.Types      (Assertion (IsValidated, OwnFundsEqual), Event (..),
                                             Notification (BlockValidated, CurrentSlot), Trace, Wallet)

api :: Proxy API
api = Proxy

wallets :: ClientM [Wallet]
fetchWallet :: Wallet -> ClientM Wallet
createWallet :: Wallet -> ClientM NoContent
myKeyPair' :: Wallet -> ClientM KeyPair
createPaymentWithChange' :: Wallet -> Value -> ClientM (Set TxIn, Maybe TxOut)
submitTxn' :: Wallet -> Tx -> ClientM [Tx]
getTransactions :: ClientM [Tx]
processPending :: ClientM [Tx]
blockValidated :: Wallet -> Block -> ClientM ()
getAddresses :: Wallet -> ClientM AddressMap
startWatching' :: Wallet -> Address -> ClientM NoContent
getSlot :: Wallet -> ClientM Slot
setSlot :: Wallet -> Slot -> ClientM ()
assertOwnFundsEq :: Wallet -> Value -> ClientM NoContent
assertIsValidated :: Tx -> ClientM NoContent
(wallets :<|> fetchWallet :<|> createWallet :<|> myKeyPair' :<|> createPaymentWithChange' :<|> submitTxn' :<|> getAddresses :<|> startWatching' :<|> getSlot :<|> getTransactions) :<|> (blockValidated :<|> setSlot) :<|> processPending  :<|> (assertOwnFundsEq :<|> assertIsValidated) =
  client api

data Environment = Environment
  { getWallet    :: Wallet
  , getClientEnv :: ClientEnv
  }

newtype WalletClient a = WalletClient
  { unWalletClient :: ReaderT Environment (WriterT [Tx] ClientM) a
  } deriving ( Functor
             , Applicative
             , Monad
             , MonadReader Environment
             , MonadWriter [Tx]
             )

runWalletClient ::
     Environment -> WalletClient a -> IO (Either ServantError (a, [Tx]))
runWalletClient env act =
  runClientM
    (runWriterT (runReaderT (unWalletClient act) env))
    (getClientEnv env)

liftWallet :: (Wallet -> ClientM a) -> WalletClient a
liftWallet action = do
  wallet <- asks getWallet
  WalletClient $ lift $ lift $ action wallet

runWalletAction ::
     ClientEnv -> Wallet -> WalletClient a -> ExceptT ServantError IO [Tx]
runWalletAction clientEnv wallet action = do
  let env = Environment wallet clientEnv
  eRes <- lift $ runWalletClient env action
  case eRes of
    Left e        -> throwError e
    Right (_, tx) -> pure tx

instance WalletAPI WalletClient where
  submitTxn tx = liftWallet (`submitTxn'` tx) >> tell [tx]
  myKeyPair = liftWallet myKeyPair'
  createPaymentWithChange value = liftWallet (`createPaymentWithChange'` value)
  register _ _ = pure () -- TODO: Keep track of triggers in emulated wallet
  watchedAddresses = liftWallet getAddresses
  slot = liftWallet getSlot
  startWatching a = void $ liftWallet (`startWatching'` a)

handleNotification :: Notification -> (Wallet -> ClientM ())
handleNotification (BlockValidated block) = (`blockValidated` block)
handleNotification (CurrentSlot slt)      = (`setSlot` slt)

assert :: Assertion -> ClientM ()
assert (IsValidated tx)             = void $ assertIsValidated tx
assert (OwnFundsEqual wallet value) = void $ assertOwnFundsEq wallet value

eval :: ClientEnv -> Event WalletClient a -> ExceptT ServantError IO a
eval clientEnv =
  \case
    WalletAction wallet action -> runWalletAction clientEnv wallet action
    WalletRecvNotification wallet trigger ->
      fold <$>
      traverse
        (runWalletAction clientEnv wallet . liftWallet . handleNotification)
        trigger
    BlockchainProcessPending -> ExceptT $ runClientM processPending clientEnv
    Assertion a -> ExceptT $ runClientM (assert a) clientEnv

process :: ClientEnv -> Trace WalletClient a -> ExceptT ServantError IO a
process clientEnv = interpretWithMonad (eval clientEnv)
