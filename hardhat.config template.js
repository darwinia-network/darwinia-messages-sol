require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-etherscan");
require('@openzeppelin/hardhat-upgrades');
require('hardhat-abi-exporter');

const mnemonic = "";

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
          version: "0.6.12",
          settings: {
            optimizer: {
              enabled: true,
              runs: 200
            }
          }
        }
      ]
    },
    defaultNetwork: 'mainnet',
    networks: {
      hardhat: {
      },
      dev: {
        url: 'http://localhost:8545/',
        // url: 'http://127.0.0.1:8545/',
        network_id: "*",
        gasPrice: 4000000000
      },
      geth: {
        url: 'http://127.0.0.1:8543/',
        network_id: "*",
        gasPrice: 1,
        accounts: {
          mnemonic: mnemonic
        }
      },
      ropsten: {
        url: 'https://eth-ropsten.alchemyapi.io/v2/',
        network_id: "*",
        gasPrice: 20000000000,
        accounts: {
          mnemonic: mnemonic,
        },
        timeout: 100000
      },
      mainnet: {
        url: 'https://eth-mainnet.alchemyapi.io/v2/',
        network_id: "1",
        gasPrice: 53100000000,
        timeout: 1000000
      },
      kovan: {
        url: 'https://eth-kovan.alchemyapi.io/v2/',
        network_id: "*",
        gasPrice: 10000000000,
        accounts: {
          mnemonic: mnemonic,
        },
        timeout: 200000
      }
    },
    etherscan: {
      apiKey: ''
    },
    abiExporter: {
      path: './abi/',
      clear: false,
      flat: false,
      only: [],
    }
};

