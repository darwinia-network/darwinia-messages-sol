const hre = require("hardhat");

// goerliEndpoint: 0x964cEcC12CD1aCf48f6EF85c4B1871C02bC1ee52
// pangolinEndpoint: 0x4D554790d20F0162dFb459C73fCFB57F563dC75a
async function main() {
  const goerliGatewayAddress = process.argv[2];
  const pangolinGatewayAddress = process.argv[3];

  const goerliChainId = 0;
  const pangolinChainId = 1;

  console.log("Setting up endpoints...");

  //////////////////////////
  // GOERLI Endpoint
  //////////////////////////
  hre.changeNetwork("goerli");
  const GoerliEndpoint = await hre.ethers.getContractFactory(
    "DarwiniaEndpoint"
  );
  const goerliEndpoint = await GoerliEndpoint.deploy(
    pangolinGatewayAddress,
    "0x9B5010d562dDF969fbb85bC72222919B699b5F54",
    "0x6c73B30a48Bb633DC353ed406384F73dcACcA5C3"
  );
  await goerliEndpoint.deployed();
  console.log(` goerliEndpoint: ${goerliEndpoint.address}`);

  // Add it to the gateway
  let MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const goerliGateway = await MessageGateway.attach(goerliGatewayAddress);
  goerliGateway.updateEndpoint(pangolinChainId, goerliEndpoint.address);

  //////////////////////////
  // PANGOLIN Endpoint
  //////////////////////////
  hre.changeNetwork("pangolin");
  const DarwiniaEndpoint = await hre.ethers.getContractFactory(
    "DarwiniaEndpoint"
  );
  const pangolinEndpoint = await DarwiniaEndpoint.deploy(
    goerliGatewayAddress,
    "0xAbd165DE531d26c229F9E43747a8d683eAD54C6c",
    "0x4DBdC9767F03dd078B5a1FC05053Dd0C071Cc005"
  );
  await pangolinEndpoint.deployed();
  console.log(` pangolinEndpoint: ${pangolinEndpoint.address}`);

  // Add it to the gateway
  MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const pangolinGateway = await MessageGateway.attach(pangolinGatewayAddress);
  pangolinGateway.updateEndpoint(goerliChainId, pangolinEndpoint.address);

  //////////////////////////
  // CONNECT THE ENDPOINTS TO EACH OTHER
  //////////////////////////
  await pangolinEndpoint.setRemoteEndpointAddress(goerliEndpoint.address);
  hre.changeNetwork("goerli");
  await goerliEndpoint.setRemoteEndpointAddress(pangolinEndpoint.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
