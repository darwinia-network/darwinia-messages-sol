const hre = require("hardhat");

// hub: 0x1F7E9D02cA0813A35b707f88440024Bf3baB5355
async function main() {
  const pangolinGatewayAddress = process.argv[2];

  // deploy hub
  hre.changeNetwork("pangolin");
  const DarwiniaMessageHub = await hre.ethers.getContractFactory(
    "DarwiniaMessageHub"
  );
  const hub = await DarwiniaMessageHub.deploy(pangolinGatewayAddress);
  await hub.deployed();
  console.log(`hub: ${hub.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
