require('dotenv').config({ path: '../../../.env' });
process.env.HARDHAT_NETWORK = "goerli";
const hre = require("hardhat");

async function main() {
    const EthereumEndpoint = await hre.ethers.getContractFactory("EthereumEndpoint");
    const endpoint = await EthereumEndpoint.deploy(
        "0x5a10ca57e07133AA5132eF29BA1EBf0096a302B0",
        "0xA10D0C6e04845A5e998d1936249A30563c553417",
        "0x5a10ca57e07133AA5132eF29BA1EBf0096a302B0"
    );
    await endpoint.deployed();

    console.log(
        `Ethereum Endpoint: ${endpoint.address}`
    );
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
