const hre = require("hardhat");

// goerliGateway: 0x770A595adfDB611BC508fdAe9e11E15AE337EF30
// pangolinGateway: 0x47480EA95B49F7A9ACe1e15e76696ab43C16EDB6
// curl -fsS https://pangolin-rpc.darwinia.network -d '{"id":1,"jsonrpc":"2.0","method":"eth_call","params":[{"data":"0x7f18dc85","gas":"0x5b8d80","to":"0xACa20c8b5D34f734DB0B0DA019C17ABEbaD3D378"},"latest"]}' -H 'Content-Type: application/json'
async function main() {
  console.log("Setting up gateways...");

  hre.changeNetwork("goerli");
  let MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const goerliGateway = await MessageGateway.deploy();
  await goerliGateway.deployed();
  console.log(` goerliGateway: ${goerliGateway.address}`);

  hre.changeNetwork("pangolin");
  MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const pangolinGateway = await MessageGateway.deploy();
  await pangolinGateway.deployed();
  console.log(` pangolinGateway: ${pangolinGateway.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
