process.env.HARDHAT_NETWORK = "pangolin"
const hre = require("hardhat");

async function main() {
    const EthereumEndpoint = await hre.ethers.getContractFactory("EthereumEndpoint");
    const endpoint = await EthereumEndpoint.deploy();
    await endpoint.deployed();

    console.log(
        `endpoint deployed: ${endpoint.address}`
    );

    const options = {value: hre.ethers.utils.parseEther("1")}
    const tx = await endpoint.executeOnAstar(
        "0x5a10ca57e07133AA5132eF29BA1EBf0096a302B0", 
        "0x1003e2d20000000000000000000000000000000000000000000000000000000000000002",
        options
    )

    console.log((await tx.wait()).transactionHash)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
