const hre = require("hardhat");

async function main() {
  const goerliGatewayAddress = process.argv[2];
  const hubAddress = process.argv[3];

  // call router from gateway to redirect `call` to rocstar
  hre.changeNetwork("goerli");
  const MessageGateway = await hre.ethers.getContractFactory("MessageGateway");
  const goerliGateway = MessageGateway.attach(goerliGatewayAddress);
  const message = hre.ethers.utils.defaultAbiCoder.encode(
    ["bytes2", "bytes", "uint64", "uint64", "uint128"],
    ["0x591f", "0x0a070c313233", "5000000000", "65536", "5000000000000000000"]
  );
  const fee = await goerliGateway.estimateFee();
  console.log(`fee: ${fee}`);
  const tx = await goerliGateway.send(hubAddress, message, { value: fee });
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
