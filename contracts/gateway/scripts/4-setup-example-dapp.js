const hre = require("hardhat");

// goerliDapp: 0x6c1D7335a362138e5E5c8831C838a46d88316f5C
// pangolinDapp: 0x770A595adfDB611BC508fdAe9e11E15AE337EF30
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
