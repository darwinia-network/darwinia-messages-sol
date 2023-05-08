const hre = require("hardhat");

// hub: 0x30Af3Ac3a7C74083c9F47E4d54722cEc760f4237
async function main() {
  const pangolinMsgportAddress = process.argv[2];

  // deploy hub
  hre.changeNetwork("pangolin");
  const DarwiniaMessageHub = await hre.ethers.getContractFactory(
    "DarwiniaMessageHub"
  );
  const hub = await DarwiniaMessageHub.deploy(
    "0xe520", // pangolin parachain id
    "0x2100", // polkadotXcm.send call index
    pangolinMsgportAddress
  );
  await hub.deployed();
  console.log(`hub: ${hub.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
