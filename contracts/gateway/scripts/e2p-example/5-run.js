const hre = require("hardhat");

async function main() {
  const goerliDappAddress = process.argv[2];
  const pangolinDappAddress = process.argv[3];

  hre.changeNetwork("goerli");
  const GoerliDapp = await hre.ethers.getContractFactory("GoerliDapp");
  const goerliDapp = GoerliDapp.attach(goerliDappAddress);

  // Run
  const fee = 1_000_000_000_000;
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
