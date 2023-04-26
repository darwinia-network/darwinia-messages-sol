const hre = require("hardhat");

// goerliGateway: 0x62A24f47D5a4f654feB2D4a1CFC6082cd2D4bE6E
// pangolinGateway: 0x512A739F0826b9fcD437601A3D364e08428d22C2
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
