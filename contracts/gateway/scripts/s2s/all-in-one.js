const hre = require("hardhat");

async function main() {
  const pangolinEndpointAddress = "0xE8C0d3dF83a07892F912a71927F4740B8e0e04ab";
  const pangoroEndpointAddress = "0x23E31167E3D46D64327fdd6e783FE5391427B728";

  ////////////////////////////////////
  // Setup gateways
  ////////////////////////////////////
  hre.changeNetwork("pangolin");
  console.log("Setting up pangolin gateway...");
  let MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const pangolinChainId = 0;
  let pangolinGateway = await MessageGateway.deploy(pangolinChainId);
  await pangolinGateway.deployed();
  const pangolinGatewayAddress = pangolinGateway.address;
  console.log(`  pangolinGateway: ${pangolinGatewayAddress}`);

  hre.changeNetwork("pangoro");
  console.log("Setting up pangoro gateway...");
  MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const pangoroChainId = 1;
  let pangoroGateway = await MessageGateway.deploy(pangoroChainId);
  await pangoroGateway.deployed();
  const pangoroGatewayAddress = pangoroGateway.address;
  console.log(`  pangoroGateway: ${pangoroGatewayAddress}`);

  ////////////////////////////////////
  // Setup endpoints
  ////////////////////////////////////
  console.log("Setting up pangolin endpoint...");
  const S2sPangolinEndpoint = await hre.ethers.getContractFactory(
    "DarwiniaS2sEndpoint"
  );
  const s2sPangolinAdapter = await S2sPangolinAdapter.deploy(
    pangolinEndpointAddress
  );
  await s2sPangolinAdapter.deployed();
  const s2sPangolinAdapterAddress = s2sPangolinAdapter.address;
  console.log(`  s2sPangolinAdapter: ${s2sPangolinAdapterAddress}`);

  hre.changeNetwork("pangoro");
  const S2sPangoroAdapter = await hre.ethers.getContractFactory(
    "DarwiniaS2sAdapter"
  );
  const s2sPangoroAdapter = await S2sPangoroAdapter.deploy(
    pangoroEndpointAddress
  );
  await s2sPangoroAdapter.deployed();
  console.log(`  s2sPangoroAdapter: ${s2sPangoroAdapter.address}`);

  // CONNECT TO EACH OTHER
  await s2sPangoroAdapter.setRemoteAdapterAddress(s2sPangolinAdapter.address);
  hre.changeNetwork("pangolin");
  await s2sPangolinAdapter.setRemoteAdapterAddress(s2sPangoroAdapter.address);

  ////////////////////////////////////
  // Add adapter to gateway
  ////////////////////////////////////
  console.log("Add pangolin adapter to pangolin gateway...");
  MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  pangolinGateway = await MessageGateway.attach(pangolinGatewayAddress);

  const adapterId = 3; // IMPORTANT!!! This needs to be +1 if the adapter is changed.
  const tx = await pangolinGateway.setAdapterAddress(
    adapterId,
    s2sPangolinAdapterAddress
  );
  console.log(
    `  pangolinGateway.setAdapterAddress tx: ${
      (await tx.wait()).transactionHash
    }`
  );

  ////////////////////////////////////
  // Dapp
  ////////////////////////////////////
  console.log("Setting up dapp...");
  // s2s Pangolin Dapp
  let S2sPangolinDapp = await hre.ethers.getContractFactory("S2sPangolinDapp");
  let s2sPangolinDapp = await S2sPangolinDapp.deploy(pangolinGatewayAddress);
  await s2sPangolinDapp.deployed();
  const pangolinDappAddress = s2sPangolinDapp.address;
  console.log(`  s2sPangolinDapp: ${pangolinDappAddress}`);

  // s2s Pangoro Dapp
  hre.changeNetwork("pangoro");
  const S2sPangoroDapp = await hre.ethers.getContractFactory("S2sPangoroDapp");
  const s2sPangoroDapp = await S2sPangoroDapp.deploy();
  await s2sPangoroDapp.deployed();
  const pangoroDappAddress = s2sPangoroDapp.address;
  console.log(`  s2sPangoroDapp: ${pangoroDappAddress}`);

  ////////////////////////////////////
  // Run
  ////////////////////////////////////
  console.log("Run...");
  hre.changeNetwork("pangolin");
  S2sPangolinDapp = await hre.ethers.getContractFactory("S2sPangolinDapp");
  s2sPangolinDapp = S2sPangolinDapp.attach(pangolinDappAddress);
  const fee = await estimateFee(s2sPangolinDapp, adapterId);
  console.log(`  Market fee: ${fee} wei`);

  // Run
  const tx2 = await s2sPangolinDapp.remoteAdd(adapterId, pangoroDappAddress, {
    value: fee,
  });
  console.log(`  tx: ${(await tx2.wait()).transactionHash}`);
}

async function estimateFee(pangolinDapp, adapterId) {
  const gatewayAddress = await pangolinDapp.gatewayAddress();
  const MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const gateway = MessageGateway.attach(gatewayAddress);

  const adapterAddress = await gateway.adapterAddresses(adapterId);
  const DarwiniaS2sAdapter = await hre.ethers.getContractFactory(
    "DarwiniaS2sAdapter"
  );
  const adapter = DarwiniaS2sAdapter.attach(adapterAddress);
  return await adapter.estimateFee();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
