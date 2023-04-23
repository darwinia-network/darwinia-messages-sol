const hre = require("hardhat");

//GoerliGateway: 0xfAaC4aC8537B7f19b03e6b0Ff1F2cbF65795f2c5
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
