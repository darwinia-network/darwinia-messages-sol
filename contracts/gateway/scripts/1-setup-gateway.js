const hre = require("hardhat");

//goerliGateway: 0x7Db5F281F99d12022b5809cB7A6A77B7946Ff492
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
