require("hardhat-gas-reporter");
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  gasReporter: {
    enabled: true,
    maxMethodDiff: 10,
  }
};
