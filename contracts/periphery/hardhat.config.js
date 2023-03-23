require("@nomiclabs/hardhat-waffle");
require('hardhat-abi-exporter');
require("hardhat-gas-reporter");
require("hardhat-change-network");

require('dotenv').config({ path: '../../.env' })

const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL || process.env.ALCHEMY_MAINNET_RPC_URL || "https://mainnet.infura.io"
const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL || "https://goerli.infura.io"
const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x99b3c12287537e38c90a9219d4cb074a89a16e9cdb20bf85728ebd97c343e342"

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

task("flat", "Flattens and prints contracts and their dependencies (Resolves licenses)")
  .addOptionalVariadicPositionalParam("files", "The files to flatten", undefined, types.inputFile)
  .setAction(async ({ files }, hre) => {
    let flattened = await hre.run("flatten:get-flattened-sources", { files });

    // Remove every line started with "// SPDX-License-Identifier:"
    flattened = flattened.replace(/SPDX-License-Identifier:/gm, "License-Identifier:");
    flattened = `// SPDX-License-Identifier: MIXED\n\n${flattened}`;

    // Remove every line started with "pragma experimental ABIEncoderV2;" except the first one
    flattened = flattened.replace(/pragma experimental ABIEncoderV2;\n/gm, ((i) => (m) => (!i++ ? m : ""))(0));
    console.log(flattened);
  });

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
        version: "0.8.9",
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
    pangoro: {
      url: 'https://pangoro-rpc.darwinia.network',
      network_id: "45",
      accounts: [PRIVATE_KEY],
      gas: 3_000_000,
      gasPrice: 53100000000
    },
    pangolin: {
      url: 'https://pangolin-rpc.darwinia.network',
      network_id: "43",
      accounts: [PRIVATE_KEY],
      gas: 3_000_000,
      gasPrice: 63100000000
    },
    pangolinDev: {
      url: 'http://g2.dev.darwinia.network:8888',
      network_id: "43",
      accounts: [PRIVATE_KEY],
      gas: 3_000_000,
      gasPrice: 63100000000
    },
    crab: {
      url: 'https://crab-rpc.darwinia.network',
      network_id: "44",
      accounts: [PRIVATE_KEY],
      gas: 3_000_000,
      gasPrice: 53_100_000_000
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
  }
};
