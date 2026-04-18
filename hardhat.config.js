require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: { enabled: true, runs: 200 }
    }
  },
  networks: {
    // Local development
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337
    },
    // HeLa Testnet
    hela_testnet: {
      url: process.env.HELA_TESTNET_RPC || "https://testnet-rpc.helachain.com",
      chainId: 666,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: "auto"
    },
    // HeLa Mainnet
    hela_mainnet: {
      url: process.env.HELA_MAINNET_RPC || "https://mainnet-rpc.helachain.com",
      chainId: 8668,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: "auto"
    }
  },
  etherscan: {
    apiKey: {
      hela_testnet: process.env.HELA_EXPLORER_KEY || "placeholder"
    },
    customChains: [
      {
        network: "hela_testnet",
        chainId: 666,
        urls: {
          apiURL: "https://testnet-helascan.io/api",
          browserURL: "https://testnet-helascan.io"
        }
      }
    ]
  },
  paths: {
    sources:   "./contracts",
    tests:     "./test",
    cache:     "./cache",
    artifacts: "./artifacts"
  }
};
