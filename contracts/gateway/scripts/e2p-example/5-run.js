const hre = require("hardhat");

async function main() {
  hre.changeNetwork("goerli");

  const goerliDappAddress = process.argv[2];
  const pangolinDappAddress = process.argv[3];

  const GoerliDapp = await hre.ethers.getContractFactory("GoerliDapp");
  const goerliDapp = GoerliDapp.attach(goerliDappAddress);

  const fee = await estimateFee(goerliDapp);
  console.log(`Market fee: ${fee} wei`);

  // Run
  const tx = await goerliDapp.remoteAdd(pangolinDappAddress, {
    value: fee,
  });
  console.log(
    `https://goerli.etherscan.io/tx/${(await tx.wait()).transactionHash}`
  );

  // check result
  while (true) {
    printResult(pangolinDappAddress);
    await sleep(1000 * 60 * 5);
  }
}

async function printResult(pangolinDappAddress) {
  hre.changeNetwork("pangolin");
  const PangolinDapp = await hre.ethers.getContractFactory("PangolinDapp");
  const pangolinDapp = PangolinDapp.attach(pangolinDappAddress);
  console.log(
    `pangolinDapp ${pangolinDappAddress} sum is ${await pangolinDapp.sum()}`
  );
}

async function estimateFee(goerliDapp) {
  const gatewayAddress = await goerliDapp.gatewayAddress();
  const MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const goerliGateway = MessageGateway.attach(gatewayAddress);

  const goerliAdapterAddress = goerliGateway.adapterAddress();
  const GoerliAdapter = await hre.ethers.getContractFactory("DarwiniaAdapter");
  const goerliAdapter = GoerliAdapter.attach(goerliAdapterAddress);

  return await goerliAdapter.estimateFee();
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
