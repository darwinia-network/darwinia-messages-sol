const hre = require("hardhat");

const sleep = ms => new Promise(r => setTimeout(r, ms));

exports.sleep = sleep;

exports.checkSumOnPangolin2 = async (remoteContractAddress, remoteContractName) => {
  hre.changeNetwork("pangolinDev");
  const RemoteContract = await hre.ethers.getContractFactory(remoteContractName);
  const remoteContract = RemoteContract.attach(remoteContractAddress);
  while (true) {
    console.log(`${remoteContractName}.sum is ${await remoteContract.sum()}`);
    await sleep(1000 * 60 * 5);
  }
}

exports.checkDataOnPangolin2 = async (remoteContractAddress, remoteContractName) => {
  hre.changeNetwork("pangolinDev");
  const RemoteContract = await hre.ethers.getContractFactory(remoteContractName);
  const remoteContract = RemoteContract.attach(remoteContractAddress);
  while (true) {
    console.log(`${remoteContractName}.data is ${await remoteContract.data()}`);
    await sleep(1000 * 60 * 5);
  }
}

const tractContractEvent = async (provider, filter) => {
  while (true) {
    console.log("Tracting contract events...");
    const events = await provider.getLogs(filter);
    events.forEach((event) => {
      console.log(`Received ${event}:`, hre.ethers.utils.defaultAbiCoder.decode(['string'], event.data)[0]);
    });
    await sleep(1000 * 60);
  }
}

exports.tractPangolin2EndpointEvents = async (endpointAddress) => {
  // const contract = new ethers.Contract(
  //   endpointAddress,
  //   contractAbi,
  //   provider
  // );
  const filter = {
    address: endpointAddress,
    topics: [
      hre.ethers.utils.id("Dispatched(bytes)"),
      hre.ethers.utils.id("EthereumCallSent(address,bytes)")
    ]
  };
  tractContractEvent(hre.ethers.provider, filter);
}
