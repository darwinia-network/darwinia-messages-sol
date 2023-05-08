const hre = require("hardhat");

// pangolinMsgport: 0xFCfDC5c65E21A9C1e2967e87e3894B1553b51753;
async function main() {
  hre.changeNetwork("pangolin");
  const DefaultMsgport = await hre.ethers.getContractFactory("DefaultMsgport");
  const pangolinMsgport = await DefaultMsgport.deploy();
  await pangolinMsgport.deployed();
  console.log(`pangolinMsgport: ${pangolinMsgport.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
