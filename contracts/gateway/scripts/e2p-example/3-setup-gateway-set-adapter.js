const hre = require("hardhat");

async function main() {
  const goerliGatewayAddress = process.argv[2];
  const goerliAdapterAddress = process.argv[3];

  // GOERLI GATEWAY
  hre.changeNetwork("goerli");
  const MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const goerliGateway = await MessageGateway.attach(goerliGatewayAddress);

  const tx = await goerliGateway.setAdapterAddress(goerliAdapterAddress);
  console.log(
    `https://goerli.etherscan.io/tx/${(await tx.wait()).transactionHash}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
