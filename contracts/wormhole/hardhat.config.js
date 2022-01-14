require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('hardhat-abi-exporter');

require('dotenv').config({ path: '.env' })

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY 

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  mocha: {
    timeout: 1000000
  },
  solidity: {
    compilers: [
      {
        version: "0.8.10",
        settings: {
          evmVersion: "istanbul",
          optimizer: {
            enabled: true,
            runs: 999999
          },
          outputSelection: {
            "*": {
              "*": [
                "abi",
                "devdoc",
                "metadata",
                "evm.bytecode.object",
                "evm.bytecode.sourceMap",
                "evm.deployedBytecode.object",
                "evm.deployedBytecode.sourceMap",
                "evm.methodIdentifiers"
              ],
              "": ["ast"]
            }
          }
        }
      },
      {
        version: "0.4.24",
        settings: {
          evmVersion: "byzantium",
          optimizer: {
            enabled: true,
            runs: 999999
          },
        }
      }
    ]
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      blockGasLimit: 30000000,
      accounts: [
          {
              privateKey: "10abcdef10abcdef10abcdef10abcdef10abcdef10abcdef10abcdef10abcdef",
              balance: "100000000000000000000",
          }
      ]
    },
    dev: {
      url: 'http://localhost:8545/',
      network_id: "*",
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  abiExporter: {
    path: './abi/',
    clear: false,
    flat: false,
    only: [],
  }
};

