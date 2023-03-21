require('dotenv').config({ path: '../../../.env' });
process.env.HARDHAT_NETWORK = "goerli";
const hre = require("hardhat");

async function main() {
    const ethereumEndpointAddress = process.argv[2];

    const EthereumEndpoint = await hre.ethers.getContractFactory("EthereumEndpoint");
    const endpoint = EthereumEndpoint.attach(ethereumEndpointAddress);

    console.log(
        `Ethereum Endpoint: ${endpoint.address}`
    );

    const tx = await endpoint.dispatchOnParachain(
        "0x591f", // dest paraid
        "0x0a070c313233", // calldata
        6000000000, // weight
        {
            value: hre.ethers.utils.parseEther("1") // should >= marketFee ?
        }
    )

    console.log((await tx.wait()).transactionHash)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
