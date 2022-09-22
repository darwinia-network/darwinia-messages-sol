process.env.HARDHAT_NETWORK = "moonbase"
const hre = require("hardhat");

async function main() {
    const moonbase_endpoint = process.argv[2]
    const Caller = await hre.ethers.getContractFactory("RemoteExecute_FromMoonbaseToPangolin");
    const caller = await Caller.deploy(moonbase_endpoint);

    await caller.deployed();
    
    console.log(
        `${caller.address}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});