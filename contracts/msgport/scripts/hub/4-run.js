const hre = require("hardhat");

// call rocstar from goerli
async function main() {
  const goerliMsgportAddress = process.argv[2];
  const hubAddress = process.argv[3];

  // call router from msgport to redirect `call` to rocstar
  hre.changeNetwork("goerli");
  const DefaultMsgport = await hre.ethers.getContractFactory("DefaultMsgport");
  const goerliMsgport = DefaultMsgport.attach(goerliMsgportAddress);

  // message format:
  //  - paraId: bytes2
  //  - call: bytes
  //  - refTime: uint64
  //  - proofSize: uint64
  //  - fungible: uint128
  const message = hre.ethers.utils.defaultAbiCoder.encode(
    ["bytes2", "bytes", "uint64", "uint64", "uint128"],
    ["0x591f", "0x0a070c313233", "5000000000", "65536", "5000000000000000000"]
  );
  const fee = await goerliMsgport.estimateFee();
  console.log(`fee: ${fee}`);
  const tx = await goerliMsgport.send(hubAddress, message, { value: fee });
  console.log(
    `https://goerli.etherscan.io/tx/${(await tx.wait()).transactionHash}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
