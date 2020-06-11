const ConvertLib = artifacts.require("ConvertLib");
const DarwiniaRelay = artifacts.require("DarwiniaRelay");

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, DarwiniaRelay);
  deployer.deploy(DarwiniaRelay);
};
