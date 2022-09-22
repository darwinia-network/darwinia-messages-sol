process.env.HARDHAT_NETWORK = "moonbase"
const hre = require("hardhat");

async function main() {
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