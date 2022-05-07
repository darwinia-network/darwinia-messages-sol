require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('hardhat-abi-exporter');

require('dotenv').config({ path: '../../.env' })

const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL || process.env.ALCHEMY_MAINNET_RPC_URL || "https://mainnet.infura.io"
const RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL || "https://rinkeby.infura.io"
const ROPSTEN_RPC_URL = process.env.ROPSTEN_RPC_URL || "https://ropsten.infura.io"
const KOVAN_RPC_URL = process.env.KOVAN_RPC_URL     || "https://kovan.infura.io"
const BSCTEST_RPC_URL = process.env.BSCTEST_RPC_URL || "https://data-seed-prebsc-1-s1.binance.org:8545"
const PRIVATE_KEY = process.env.PRIVATE_KEY         || "0x99b3c12287537e38c90a9219d4cb074a89a16e9cdb20bf85728ebd97c343e342"

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
        version: "0.6.9",
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
      }
    ]
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  defaultNetwork: 'ropsten',
  networks: {
    hardhat: {
    },
    dev: {
      url: 'http://localhost:8545/',
      network_id: "*",
      accounts: [PRIVATE_KEY]
    },
    ropsten: {
      url: ROPSTEN_RPC_URL,
      network_id: "*",
      accounts: [PRIVATE_KEY],
      timeout: 100000
    },
    mainnet: {
      url: MAINNET_RPC_URL,
      network_id: "1",
      gasPrice: 53100000000,
      accounts: [PRIVATE_KEY],
      timeout: 1000000
    },
    kovan: {
      url: KOVAN_RPC_URL,
      network_id: "*",
      accounts: [PRIVATE_KEY],
      timeout: 200000
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY
  },
  abiExporter: {
    path: './abi/',
    clear: false,
    flat: false,
    only: [],
  }
};

