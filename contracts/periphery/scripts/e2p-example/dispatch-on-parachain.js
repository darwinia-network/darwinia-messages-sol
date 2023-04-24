const hre = require("hardhat");

async function main() {
  const caller2Address = process.argv[2];
  await remoteDispatchOnParachain(caller2Address);
}

async function remoteDispatchOnParachain(caller2Address) {
  hre.changeNetwork("goerli");
  const Caller2 = await hre.ethers.getContractFactory("Caller2");
  const caller2 = Caller2.attach(caller2Address);

  console.log(`GoerliEndpoint: ${await caller2.endpointAddress()}`);

  // Get market fee
  const GoerliEndpoint = await hre.ethers.getContractFactory("GoerliEndpoint");
  const goerliEndpoint = GoerliEndpoint.attach(await caller2.endpointAddress());
  const fee = await goerliEndpoint.fee();
  console.log(`End user will pay: ${fee} wei`);

  // dispatchOnParachain
  const tx = await caller2.dispatchOnParachain(
    "0x711f", // dest paraid 2012
    "0x0a070c313233", // calldata
    "5000000000", // weight
    "20000000000000000000", // fungible
    {
      value: fee,
    }
  );

  console.log(
    `https://goerli.etherscan.io/tx/${(await tx.wait()).transactionHash}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
