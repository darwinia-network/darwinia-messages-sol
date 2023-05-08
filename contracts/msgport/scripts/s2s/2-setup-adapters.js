const hre = require("hardhat");

// s2sPangolinAdapter: 0x719596B4e6F0865a2919647A1731a1435dFcda5f
// s2sPangoroAdapter: 0x046163b94B4c43D030f4661635A5abF5f3130261
async function main() {
  // PANGOLIN Adapter
  hre.changeNetwork("pangolin");
  const S2sPangolinAdapter = await hre.ethers.getContractFactory(
    "DarwiniaS2sAdapter"
  );
  const s2sPangolinAdapter = await S2sPangolinAdapter.deploy(
    "0xE8C0d3dF83a07892F912a71927F4740B8e0e04ab"
  );
  await s2sPangolinAdapter.deployed();
  console.log(`s2sPangolinAdapter: ${s2sPangolinAdapter.address}`);

  // PANGORO Adapter
  hre.changeNetwork("pangoro");
  const S2sPangoroAdapter = await hre.ethers.getContractFactory(
    "DarwiniaS2sAdapter"
  );
  const s2sPangoroAdapter = await S2sPangoroAdapter.deploy(
    "0x23E31167E3D46D64327fdd6e783FE5391427B728"
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
