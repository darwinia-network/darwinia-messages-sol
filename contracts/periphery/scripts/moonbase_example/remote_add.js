process.env.HARDHAT_NETWORK = "moonbase"
const hre = require("hardhat");

async function main() {
    const caller_address = process.argv[2]
    const callee_adderss = process.argv[3]

    const caller = await hre.ethers.getContractAt("RemoteExecute_FromMoonbaseToPangolin", caller_address);
    // const Caller = await hre.ethers.getContractFactory("RemoteExecute_FromMoonbaseToPangolin");
    // const caller = await Caller.attach(caller_address);

    const fee = hre.ethers.utils.parseEther("1");
    const tx = await caller.remoteAdd(callee_adderss, { value: fee })

    console.log(tx.hash)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});