process.env.HARDHAT_NETWORK = "pangolin"
const hre = require("hardhat");

async function main() {
    const PangolinEndpoint = await hre.ethers.getContractFactory("PangolinEndpoint");
    const endpoint = await PangolinEndpoint.deploy();

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