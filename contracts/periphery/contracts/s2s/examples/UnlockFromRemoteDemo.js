// Run UnlockFromRemoteDemo on Pangolin
//   npx hardhat run --network pangolin contracts/s2s/examples/UnlockFromRemoteDemo.js
//
// View result tx on subscan:
//   https://pangolin.subscan.io/tx/0x...
async function main() {
    // We get the contract to deploy
    const UnlockFromRemoteDemo = await ethers.getContractFactory("UnlockFromRemoteDemo");
    const demo = await UnlockFromRemoteDemo.deploy();
    await demo.deployed();
    await demo.deployTransaction.wait();
    console.log("Deployed to:", demo.address);

    // Send transaction
    const tx = await demo.unlockFromRemote({
      value: BigInt(200000000000000000000), // 200 PRING, The fee to use the cross-chain service, determined by the Fee Market
    });, determined by the Fee Market
    await tx.wait();
    console.log("txhash:", tx["hash"]);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });