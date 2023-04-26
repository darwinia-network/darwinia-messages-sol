const hre = require("hardhat");

// hub: 0xB8537c5e9E8A01897A1F8f125d46bA9DDd87da66
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
