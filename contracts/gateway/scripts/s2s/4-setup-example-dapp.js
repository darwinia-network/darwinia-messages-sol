const hre = require("hardhat");

// s2sPangolinDapp: 0xDf2180554eFF86d0e910E8B6652EDf3c59C37e97
// s2sPangoroDapp: 0x758322f03444B53eCe0c3f1ADbB7fb021FEB68d1
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
