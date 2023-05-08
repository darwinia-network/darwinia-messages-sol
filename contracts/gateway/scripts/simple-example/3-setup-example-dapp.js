const hre = require("hardhat");

// goerliDapp: 0x37d2FA1cAB71072e8dC7Ad651eecc1652C3780d7
// pangolinDapp: 0x88c3B318Dad79599829F805C9329B4e9F27A68ab
async function main() {
  const goerliMsgportAddress = process.argv[2];

  // Goerli Dapp
  hre.changeNetwork("goerli");
  const GoerliDapp = await hre.ethers.getContractFactory("GoerliDapp");
  const goerliDapp = await GoerliDapp.deploy(goerliMsgportAddress);
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
