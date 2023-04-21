const hre = require("hardhat");

async function main() {
  const caller2Address = process.argv[2];
  await remoteDispatchOnParachain(caller2Address);
}

async function remoteDispatchOnParachain(caller2Address) {
  hre.changeNetwork("goerli");
  const Caller2 = await hre.ethers.getContractFactory("Caller2");
  const caller2 = Caller2.attach(caller2Address);

  // Get goerli endpoint
  const goerliEndpointAdress = await caller2.endpointAddress();
  console.log(`GoerliEndpoint: ${goerliEndpointAdress}`);
  const GoerliEndpoint = await hre.ethers.getContractFactory("GoerliEndpoint");
  const goerliEndpoint = GoerliEndpoint.attach(goerliEndpointAdress);

  // Get market fee from goerli endpoint
  let fee;
  try {
    fee = await goerliEndpoint.fee();
    console.log(`Cross-chain market fee: ${fee} wei`);
  } catch (e) {
    console.log(`Error getting fee from fee market: ${e.message}`);
    console.log(
      `This is because there is no relayer or the collateral of the relayer is too low.`
    );
    return;
  }

  // Check pangolin endpoint has enough balance
  const pangolin2EndpointAddress = await goerliEndpoint.remoteEndpoint();
  hre.changeNetwork("pangolin");
  const balance = await hre.ethers.provider.getBalance(
    pangolin2EndpointAddress
  );
  console.log(`Balance of Pangolin2Endpoint: ${balance} wei`);

  //   // Remote remark on pangolin
  //   hre.changeNetwork("goerli");
  //   const tx = await caller2.remoteRemarkWithEvent({
  //     value: fee,
  //   });
  //   console.log(
  //     `https://goerli.etherscan.io/tx/${(await tx.wait()).transactionHash}`
  //   );

  // Remote dispatch on parachain
  hre.changeNetwork("goerli");
  const tx = await caller2.dispatchOnParachain(
    "0x711f", // "0x591f", // dest paraid
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

  //   // Listen for goerli events
  //   const filter = goerliEndpoint.filters.DispatchCall();
  //   goerliEndpoint.on(filter, (from, to, data) => {
  //     console.log(`DispatchCall event received: ${from} -> ${to} ${data}`);
  //   });

  //   // Listen for pangolin events
  //   hre.changeNetwork("pangolin");
  //   const Pangolin2Endpoint = await hre.ethers.getContractFactory(
  //     "Pangolin2Endpoint"
  //   );
  //   const pangolin2Endpoint = Pangolin2Endpoint.attach(pangolin2EndpointAddress);
  //   pangolin2Endpoint.on("Dispatched", (from, to, data) => {
  //     console.log(`Dispatched event received: ${from} -> ${to} ${data}`);
  //   });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
