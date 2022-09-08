process.env.HARDHAT_NETWORK = "moonbase"
const hre = require("hardhat");

async function main() {

    // const XcmTransactorV1 = await hre.ethers.getContractFactory("XcmTransactorV1");
    // const lib = await XcmTransactorV1.deploy();
    // await lib.deployed();

    const MoonbaseEndpoint = await hre.ethers.getContractFactory("MoonbaseEndpoint");
    const endpoint = await MoonbaseEndpoint.deploy();
    await endpoint.deployed();

    console.log(
        `${endpoint.address}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});