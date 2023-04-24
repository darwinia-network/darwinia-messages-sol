const hre = require("hardhat");

async function main() {
  const pangolinGatewayAddress = process.argv[2];
  const s2sPangolinAdapterAddress = process.argv[3];

  hre.changeNetwork("pangolin");
  const MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const pangolinGateway = await MessageGateway.attach(pangolinGatewayAddress);

  const tx = await pangolinGateway.setAdapterAddress(
    0,
    s2sPangolinAdapterAddress
  );
  console.log(`tx: ${(await tx.wait()).transactionHash}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
