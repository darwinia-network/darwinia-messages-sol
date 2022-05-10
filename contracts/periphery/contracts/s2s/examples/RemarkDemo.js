// Run RemarkDemo on Crab
//   npx hardhat run --network pangolin contracts/s2s/examples/RemarkDemo.js
//
// View result tx on subscan:
//   https://crab.subscan.io/tx/0x...
async function main() {
    // We get the contract to deploy
    const RemarkDemo = await ethers.getContractFactory("RemarkDemo");
    const demo = await RemarkDemo.deploy();
    await demo.deployed();
    await demo.deployTransaction.wait();
    console.log("Deployed to:", demo.address);

    // Send transaction
    const tx = await demo.remark({
      value: BigInt(200000000000000000000), // 200 CRAB, The fee to use the cross-chain service, determined by the Fee Market
    });
    await tx.wait();
    console.log("txhash:", tx["hash"]);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });