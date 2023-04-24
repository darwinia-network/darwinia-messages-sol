const hre = require("hardhat");

// s2sPangolinAdapter: 0xEE174FD525A1540d1cCf3fDadfeD172764b4913F
// s2sPangoroAdapter: 0x6F9f7DCAc28F3382a17c11b53Bb11F20479754b1
async function main() {
  // PANGOLIN Adapter
  hre.changeNetwork("pangolin");
  const S2sPangolinAdapter = await hre.ethers.getContractFactory(
    "DarwiniaS2sAdapter"
  );
  const s2sPangolinAdapter = await S2sPangolinAdapter.deploy(
    "0x347d0Cd647A2b4B70000072295A6e35C54B6CCf0"
  );
  await s2sPangolinAdapter.deployed();
  console.log(`s2sPangolinAdapter: ${s2sPangolinAdapter.address}`);

  // PANGORO Adapter
  hre.changeNetwork("pangoro");
  const S2sPangoroAdapter = await hre.ethers.getContractFactory(
    "DarwiniaS2sAdapter"
  );
  const s2sPangoroAdapter = await S2sPangoroAdapter.deploy(
    "0x8EFBE3B3F40ca4f7cDb2B6D07E8D055DEb956ea2"
  );
  await s2sPangoroAdapter.deployed();
  console.log(`s2sPangoroAdapter: ${s2sPangoroAdapter.address}`);

  // CONNECT TO EACH OTHER
  await s2sPangoroAdapter.setRemoteAdapterAddress(s2sPangolinAdapter.address);
  hre.changeNetwork("pangolin");
  await s2sPangolinAdapter.setRemoteAdapterAddress(s2sPangoroAdapter.address);
  console.log("Done!");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
