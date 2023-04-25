const hre = require("hardhat");

//goerliGateway: 0xEE174FD525A1540d1cCf3fDadfeD172764b4913F
async function main() {
  // GOERLI GATEWAY
  hre.changeNetwork("goerli");
  const MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const goerliGateway = await MessageGateway.deploy();
  await goerliGateway.deployed();
  console.log(`goerliGateway: ${goerliGateway.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
