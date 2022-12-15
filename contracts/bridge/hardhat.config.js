require("@nomiclabs/hardhat-waffle");
require('hardhat-abi-exporter');
require("hardhat-gas-reporter");

require('dotenv').config({ path: '../../.env' })

const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL           || process.env.ALCHEMY_MAINNET_RPC_URL                                  || "https://mainnet.infura.io"
const GOERLI_RPC_URL  = process.env.GOERLI_RPC_URL            || "https://goerli.infura.io"
const BSCTEST_RPC_URL = process.env.BSCTEST_RPC_URL           || "https://data-seed-prebsc-1-s1.binance.org:8545"
const PRIVATE_KEY     = process.env.PRIVATE_KEY               || "0x99b3c12287537e38c90a9219d4cb074a89a16e9cdb20bf85728ebd97c343e342"
const REPORT_GAS      = process.env.REPORT_GAS ? true : false

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

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
        version: "0.8.17",
        settings: {
          evmVersion: "london",
          optimizer: {
            enabled: true,
            runs: 999999,
          },
          metadata: {
            // do not include the metadata hash, since this is machine dependent
            // and we want all generated code to be deterministic
            // https://docs.soliditylang.org/en/v0.7.6/metadata.html
            bytecodeHash: 'none',
          },
        },
      },
    ]
  },
  paths: {
    sources: "./src",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      throwOnCallFailures: true,
      throwOnTransactionFailures: true,
    },
    dev: {
      url: 'http://127.0.0.1:8545/',
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
    },
    bsctest: {
      url: BSCTEST_RPC_URL,
      network_id: "*",
      accounts: [PRIVATE_KEY],
      timeout: 200000
    }
  },
  abiExporter: {
    path: './abi/',
    clear: true,
    flat: false,
    only: [],
  },
  gasReporter: {
    enabled: REPORT_GAS,
  }
};

