process.env.HARDHAT_NETWORK = "pangolin"
const hre = require("hardhat");

async function main() {
    const pangolin_endpoint = process.argv[2]
    const Caller = await hre.ethers.getContractFactory("RemoteExecute_FromPangolinToMoonbase");
    const caller = await Caller.deploy(pangolin_endpoint);

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
