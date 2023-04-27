const hre = require("hardhat");

// goerliAdapter: 0xcF7dC57e24cF3d2a31fC52f7ed9538959870Cf2A
// pangolinAdapter: 0xEF9F4db2e4ABACcB425Cb208672492f41ec667Db
async function main() {
  const goerliGatewayAddress = process.argv[2];
  const pangolinGatewayAddress = process.argv[3];

  console.log("Setting up adapters...");

  //////////////////////////
  // GOERLI Adapter
  //////////////////////////
  hre.changeNetwork("goerli");
  let GoerliAdapter = await hre.ethers.getContractFactory("DarwiniaAdapter");
  let goerliAdapter = await GoerliAdapter.deploy(
    goerliGatewayAddress,
    "0x9B5010d562dDF969fbb85bC72222919B699b5F54", // outbound lane
    "0x0F6e081B1054c59559Cf162e82503F3f560cA4AF", // inbound lane
    "0x6c73B30a48Bb633DC353ed406384F73dcACcA5C3"
  );
  await goerliAdapter.deployed();
  console.log(` goerliAdapter: ${goerliAdapter.address}`);

  // Add it to the gateway
  let MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const goerliGateway = await MessageGateway.attach(goerliGatewayAddress);
  await (await goerliGateway.setAdapter(goerliAdapter.address)).wait();

  //////////////////////////
  // PANGOLIN Adapter
  //////////////////////////
  hre.changeNetwork("pangolin");
  const DarwiniaAdapter = await hre.ethers.getContractFactory(
    "DarwiniaAdapter"
  );
  const pangolinAdapter = await DarwiniaAdapter.deploy(
    pangolinGatewayAddress,
    "0xAbd165DE531d26c229F9E43747a8d683eAD54C6c",
    "0xB59a893f5115c1Ca737E36365302550074C32023",
    "0x4DBdC9767F03dd078B5a1FC05053Dd0C071Cc005"
  );
  await pangolinAdapter.deployed();
  console.log(` pangolinAdapter: ${pangolinAdapter.address}`);

  // Add it to the gateway
  MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const pangolinGateway = await MessageGateway.attach(pangolinGatewayAddress);
  await (await pangolinGateway.setAdapter(pangolinAdapter.address)).wait();

  //////////////////////////
  // CONNECT THE ENDPOINTS TO EACH OTHER
  //////////////////////////
  console.log("Connecting adapters...");
  await pangolinAdapter.setRemoteAdapterAddress(goerliAdapter.address);
  console.log(" Connected pangolinAdapter to goerliAdapter...");

  hre.changeNetwork("goerli");
  await goerliAdapter.setRemoteAdapterAddress(pangolinAdapter.address);
  console.log(" Connected goerliAdapter to pangolinAdapter...");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
