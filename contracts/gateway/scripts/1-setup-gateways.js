const hre = require("hardhat");

async function main() {
  console.log("Setting up gateways...");

  hre.changeNetwork("goerli");
  let MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const goerliChainId = 0;
  const goerliGateway = await MessageGateway.deploy(goerliChainId);
  await goerliGateway.deployed();
  console.log(` goerliGateway: ${goerliGateway.address}`);

  hre.changeNetwork("pangolin");
  MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const pangolinChainId = 1;
  const pangolinGateway = await MessageGateway.deploy(pangolinChainId);
  await pangolinGateway.deployed();
  console.log(` pangolinGateway: ${pangolinGateway.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
