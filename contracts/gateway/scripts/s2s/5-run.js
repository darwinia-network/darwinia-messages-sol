const hre = require("hardhat");

async function main() {
  hre.changeNetwork("pangolin");

  const pangolinDappAddress = process.argv[2];
  const pangoroDappAddress = process.argv[3];

  const S2sPangolinDapp = await hre.ethers.getContractFactory(
    "S2sPangolinDapp"
  );
  const s2sPangolinDapp = S2sPangolinDapp.attach(pangolinDappAddress);

  const fee = await estimateFee(s2sPangolinDapp);
  console.log(`Market fee: ${fee} wei`);

  // // Run
  // const tx = await s2sPangolinDapp.remoteAdd(0, pangoroDappAddress, {
  //   value: fee,
  // });
  // console.log(`tx: ${(await tx.wait()).transactionHash}`);

  // // check result
  // while (true) {
  //   printResult(pangoroDappAddress);
  //   await sleep(1000 * 60 * 5);
  // }
}

async function printResult(pangoroDappAddress) {
  hre.changeNetwork("pangoro");
  const S2sPangoroDapp = await hre.ethers.getContractFactory("S2sPangoroDapp");
  const s2sPangoroDapp = S2sPangoroDapp.attach(pangoroDappAddress);
  console.log(
    `s2sPangoroDapp ${pangoroDappAddress} sum is ${await s2sPangoroDapp.sum()}`
  );
}

async function estimateFee(dapp) {
  const gatewayAddress = await dapp.gatewayAddress();
  const MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const gateway = MessageGateway.attach(gatewayAddress);

  const adapterAddress = await gateway.adapterAddresses(0);
  console.log(`adapterAddress: ${adapterAddress}`);
  const DarwiniaS2sAdapter = await hre.ethers.getContractFactory(
    "DarwiniaS2sAdapter"
  );
  const adapter = DarwiniaS2sAdapter.attach(adapterAddress);

  console.log(`endpointAddress: ${await adapter.endpointAddress()}`);
  return await adapter.estimateFee();
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
