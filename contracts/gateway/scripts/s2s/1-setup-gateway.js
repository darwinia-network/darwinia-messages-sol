const hre = require("hardhat");

// pangolinGateway: 0xFCfDC5c65E21A9C1e2967e87e3894B1553b51753;
async function main() {
  hre.changeNetwork("pangolin");
  const MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const pangolinGateway = await MessageGateway.deploy();
  await pangolinGateway.deployed();
  console.log(`pangolinGateway: ${pangolinGateway.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
