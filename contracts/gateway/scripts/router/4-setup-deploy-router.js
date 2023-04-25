const hre = require("hardhat");

// router: 0x0d3E68D53D0807E36D303b86bc2c2a13A0966eAb
async function main() {
  // deploy router
  hre.changeNetwork("pangolin");
  const PangolinRouterToParachain = await hre.ethers.getContractFactory(
    "PangolinRouterToParachain"
  );
  const router = await PangolinRouterToParachain.deploy();
  await router.deployed();
  console.log(`router: ${router.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
