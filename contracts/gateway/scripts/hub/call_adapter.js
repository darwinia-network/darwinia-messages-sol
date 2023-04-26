const hre = require("hardhat");

async function main() {
  const adapterAddress = process.argv[2];

  // call router from gateway to redirect `call` to rocstar
  hre.changeNetwork("pangolin");
  const DarwiniaAdapter = await hre.ethers.getContractFactory(
    "DarwiniaAdapter"
  );
  const pangolinAdapter = await DarwiniaAdapter.attach(adapterAddress);
  const tx = await pangolinAdapter.epRecv(
    "0xD93E82b9969CC9a016Bc58f5D1D7f83918fd9C79",
    "0xB8537c5e9E8A01897A1F8f125d46bA9DDd87da66",
    "0x711f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000012a05f200000000000000000000000000000000000000000000000001158e460913d0000000000000000000000000000000000000000000000000000000000000000000050007081234000000000000000000000000000000000000000000000000000000"
  );
  console.log((await tx.wait()).transactionHash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
