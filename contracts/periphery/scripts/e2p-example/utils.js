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

// write a code to listen to a ethereum transaction event and print the event data
// event Dispatched(bytes call)
exports.listenToEvmEvent = (contractAddress, eventAbi) => {
  filter = {
    address: contractAddress,
    topics: [
      hre.ethers.utils.id(eventAbi)
    ]
  }
  hre.ethers.provider.on(filter, (log, event) => {
    console.log(log);
    console.log(event);
  })
}
