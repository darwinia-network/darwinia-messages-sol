require("@nomiclabs/hardhat-waffle");
require('hardhat-abi-exporter');
require("hardhat-gas-reporter");
require("./src/tasks/gasUsageMerkleProof");

require('dotenv').config({ path: '../../.env' })

const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL           || process.env.ALCHEMY_MAINNET_RPC_URL                                  || "https://mainnet.infura.io"
const GOERLI_RPC_URL  = process.env.GOERLI_RPC_URL            || "https://goerli.infura.io"
const PRIVATE_KEY     = process.env.PRIVATE_KEY               || "0x99b3c12287537e38c90a9219d4cb074a89a16e9cdb20bf85728ebd97c343e342"
const REPORT_GAS = process.env.REPORT_GAS ? true : false

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
        version: "0.6.0",
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
    },
    dev: {
      url: 'http://localhost:8545/',
      network_id: "*",
      accounts: [PRIVATE_KEY]
    },
    goerli: {
      url: GOERLI_RPC_URL,
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
    }
  },
  abiExporter: {
    path: './abi/',
    clear: false,
    flat: false,
    only: [],
  },
  gasReporter: {
    enabled: REPORT_GAS,
  }
};

