const hre = require("hardhat");

async function main() {
  const goerliGatewayAddress = process.argv[2];

  // Goerli Dapp
  hre.changeNetwork("goerli");
  const GoerliDapp = await hre.ethers.getContractFactory("GoerliDapp");
  const goerliDapp = await GoerliDapp.deploy(goerliGatewayAddress);
  await goerliDapp.deployed();
  console.log(`goerliDapp: ${goerliDapp.address}`);

  // Pangolin Dapp
  hre.changeNetwork("pangolin");
  const PangolinDapp = await hre.ethers.getContractFactory("PangolinDapp");
  const pangolinDapp = await PangolinDapp.deploy();
  await pangolinDapp.deployed();
  console.log(`pangolinDapp: ${pangolinDapp.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
