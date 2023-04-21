const hre = require("hardhat");

// PangolinGateway: 0xCB0e8B02012fb3d1d836DBEb282E41b9d8fbf187
// GoerliGateway: 0x217066ce192358Eba6D31230bc5Ef9e96810587f
async function main() {
  // PANGOLIN GATEWAY
  hre.changeNetwork("pangolin");
  const MessageGateway_1 = await hre.ethers.getContractFactory(
    "MessageGateway"
  );
  const pangolinGateway = await MessageGateway_1.deploy(
    "0xAbd165DE531d26c229F9E43747a8d683eAD54C6c",
    "0x4DBdC9767F03dd078B5a1FC05053Dd0C071Cc005"
  );
  await pangolinGateway.deployed();
  console.log(`PangolinGateway: ${pangolinGateway.address}`);

  // GOERLI GATEWAY
  hre.changeNetwork("goerli");
  const MessageGateway_2 = await hre.ethers.getContractFactory(
    "MessageGateway"
  );
  const goerliGateway = await MessageGateway_2.deploy(
    "0x9B5010d562dDF969fbb85bC72222919B699b5F54",
    "0x6c73B30a48Bb633DC353ed406384F73dcACcA5C3"
  );
  await goerliGateway.deployed();
  console.log(`GoerliGateway: ${goerliGateway.address}`);

  // CONNECT EACH GATEWAY TO THE OTHER
  await goerliGateway.setRemoteGateway(pangolinGateway.address);
  hre.changeNetwork("pangolin");
  await pangolinGateway.setRemoteGateway(goerliGateway.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
