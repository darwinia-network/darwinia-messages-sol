const hre = require("hardhat");

// s2sPangolinDapp: 0x74b673e8cb4894D926d5c7bD35B472f88E998468
// s2sPangoroDapp: 0xa2E9301Cc669e7162FCd02cBEC9FDdb010B1dF8E
async function main() {
  const pangolinGatewayAddress = process.argv[2];

  // s2s Pangolin Dapp
  hre.changeNetwork("pangolin");
  const S2sPangolinDapp = await hre.ethers.getContractFactory(
    "S2sPangolinDapp"
  );
  const s2sPangolinDapp = await S2sPangolinDapp.deploy(pangolinGatewayAddress);
  await s2sPangolinDapp.deployed();
  console.log(`s2sPangolinDapp: ${s2sPangolinDapp.address}`);

  // s2s Pangoro Dapp
  hre.changeNetwork("pangoro");
  const S2sPangoroDapp = await hre.ethers.getContractFactory("S2sPangoroDapp");
  const s2sPangoroDapp = await S2sPangoroDapp.deploy();
  await s2sPangoroDapp.deployed();
  console.log(`s2sPangoroDapp: ${s2sPangoroDapp.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
