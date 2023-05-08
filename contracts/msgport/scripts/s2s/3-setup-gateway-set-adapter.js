const hre = require("hardhat");

async function main() {
  const pangolinMsgportAddress = process.argv[2];
  const s2sPangolinAdapterAddress = process.argv[3];

  hre.changeNetwork("pangolin");
  const DefaultMsgport = await hre.ethers.getContractFactory("DefaultMsgport");
  const pangolinMsgport = await DefaultMsgport.attach(pangolinMsgportAddress);

  const tx = await pangolinMsgport.setAdapterAddress(
    3, // IMPORTANT!!! This needs to be +1 if the adapter is changed.
    s2sPangolinAdapterAddress
  );
  console.log(`tx: ${(await tx.wait()).transactionHash}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
