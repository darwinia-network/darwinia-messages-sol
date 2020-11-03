require("@nomiclabs/hardhat-waffle");
const mnemonic = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";

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
    timeout: 100000
  },
  solidity: "0.5.16",
    // defaultNetwork: 'dev',
    networks: {
      hardhat: {
      },
      dev: {
        url: 'http://127.0.0.1:8543/',
        network_id: "*",
        gasPrice: 1000000000,
        accounts: {
          mnemonic: mnemonic,

        }
      }
    }
};

