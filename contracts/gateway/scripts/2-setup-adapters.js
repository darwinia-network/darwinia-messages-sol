const hre = require("hardhat");

// pangolinAdapter: 0x05fDd0B601fBcba9320b84894c9801E1A3B6aA9A
// goerliAdapter: 0xF7f0b8e1cb13EcEd4B49230c9edF81cB5F98913a
async function main() {
  // PANGOLIN Adapter
  hre.changeNetwork("pangolin");
  const DarwiniaAdapter = await hre.ethers.getContractFactory(
    "DarwiniaAdapter"
  );
  const pangolinAdapter = await DarwiniaAdapter.deploy(
    "0xAbd165DE531d26c229F9E43747a8d683eAD54C6c",
    "0x4DBdC9767F03dd078B5a1FC05053Dd0C071Cc005"
  );
  await pangolinAdapter.deployed();
  console.log(`pangolinAdapter: ${pangolinAdapter.address}`);

  // GOERLI Adapter
  hre.changeNetwork("goerli");
  const GoerliAdapter = await hre.ethers.getContractFactory("DarwiniaAdapter");
  const goerliAdapter = await GoerliAdapter.deploy(
    "0x9B5010d562dDF969fbb85bC72222919B699b5F54",
    "0x6c73B30a48Bb633DC353ed406384F73dcACcA5C3"
  );
  await goerliAdapter.deployed();
  console.log(`goerliAdapter: ${goerliAdapter.address}`);

  // CONNECT TO EACH OTHER
  await goerliAdapter.setRemoteAdapterAddress(pangolinAdapter.address);
  hre.changeNetwork("pangolin");
  await pangolinAdapter.setRemoteAdapterAddress(goerliAdapter.address);
  console.log("Done!");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
