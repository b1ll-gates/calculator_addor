## i. Add private key to .env
## ii. npm install

## iii. **If deploy on BSC testnet, get BNB from faucet:** **[link](https://testnet.binance.org/faucet-smart)**
## iv. **Migrate contract to BSC testnet:**
```
truffle migrate --reset --network bsc_testnet
```
## v. **Mint NFT on BSC testnet:**
```
truffle exec scripts/mint.js --network bsc_testnet
```
## vi. **Migrate contract to BSC mainnet:**
```
truffle migrate --reset --network bsc_mainnet
```
## vii. **Mint NFT on BSC mainnet:**
```
truffle exec scripts/mint.js --network bsc_mainnet
```
## viii. ***TESTS**
```
truffle test --network bsc_testnet
```
