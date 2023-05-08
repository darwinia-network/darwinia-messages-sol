const hre = require("hardhat");

async function main() {
  console.log("Setting up msgports...");

  hre.changeNetwork("goerli");
  let DefaultMsgport = await hre.ethers.getContractFactory("DefaultMsgport");
  const goerliMsgport = await DefaultMsgport.deploy();
  await goerliMsgport.deployed();
  console.log(` goerliMsgport: ${goerliMsgport.address}`);

  hre.changeNetwork("pangolin");
  DefaultMsgport = await hre.ethers.getContractFactory("DefaultMsgport");
  const pangolinMsgport = await DefaultMsgport.deploy();
  await pangolinMsgport.deployed();
  console.log(` pangolinMsgport: ${pangolinMsgport.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
