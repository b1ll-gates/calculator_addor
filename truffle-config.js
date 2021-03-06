require('dotenv').config();
const privateKeys = process.env.PRIVATE_KEYS || ""
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    bsc_testnet: {
      provider: () => new HDWalletProvider(
        privateKeys.split(','),
`https://data-seed-prebsc-1-s1.binance.org:8545/`
      ),
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 300,
      skipDryRun: true
    },
    bsc_mainnet: {
      provider: () => new HDWalletProvider(
        privateKeys.split(','),
        `https://bsc-dataseed1.binance.org`
      ),
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    }
  },
  compilers: {
    solc: {
      version: ">=0.4.11 <0.8.0",
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
   development: {
        host: "127.0.0.1",
        port: 9545,
        network_id: "*",
   },
   develop: {
        port: 9545,
   }
}

/*
 *
 *Testnet BSC RPC Endpoints (ChainID 97):
Testnet(ChainID 0x61, 97 in decimal)
BSC RPC Endpoints:

https://data-seed-prebsc-1-s1.binance.org:8545/
https://data-seed-prebsc-2-s1.binance.org:8545/
https://data-seed-prebsc-1-s2.binance.org:8545/
https://data-seed-prebsc-2-s2.binance.org:8545/
https://data-seed-prebsc-1-s3.binance.org:8545/
https://data-seed-prebsc-2-s3.binance.org:8545/

 *
 *
 */
