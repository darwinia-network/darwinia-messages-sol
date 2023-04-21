const hre = require("hardhat");

async function main() {
  const goerliDappAddress = process.argv[2];
  const pangolinDappAddress = process.argv[3];

  hre.changeNetwork("goerli");
  const GoerliDapp = await hre.ethers.getContractFactory("GoerliDapp");
  const goerliDapp = GoerliDapp.attach(goerliDappAddress);

  // Get goerli endpoint
  const MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const gatewayAddress = await goerliDapp.gatewayAddress();
  console.log(`goerliGateway: ${gatewayAddress}`);
  const goerliGateway = MessageGateway.attach(gatewayAddress);

  // Get market fee from goerli endpoint
  let fee;
  try {
    fee = await goerliGateway.fee();
    console.log(`Market fee: ${fee} wei`);
  } catch (e) {
    console.log(e);
    return;
  }

  // // Check pangolin endpoint has enough balance
  // const pangolinEndpointAddress = await goerliEndpoint.REMOTE_ENDPOINT();
  // hre.changeNetwork("pangolin");
  // const balance = await hre.ethers.provider.getBalance(pangolinEndpointAddress);
  // console.log(`Balance of PangolinEndpoint: ${balance} wei`);

  // Run
  hre.changeNetwork("goerli");
  const tx = await goerliDapp.remoteAdd(pangolinDappAddress, 2, {
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
  console.log(`${pangolinDapp}.sum is ${await pangolinDapp.sum()}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
