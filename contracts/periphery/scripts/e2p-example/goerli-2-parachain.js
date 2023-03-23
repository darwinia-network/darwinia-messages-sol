const hre = require("hardhat");

async function main() {
    ////////////////////////////////////////
    // Deploy
    ////////////////////////////////////////
    // PANGOLIN
    // -------------
    hre.changeNetwork("pangolinDev");
    const Pangolin2Endpoint = await hre.ethers.getContractFactory("Pangolin2Endpoint");
    const pangolin2Endpoint = await Pangolin2Endpoint.deploy();
    await pangolin2Endpoint.deployed();
    console.log(
        `Pangolin Endpoint: ${pangolin2Endpoint.address}`
    );

    // GOERLI
    // -------------
    hre.changeNetwork("goerli");
    const GoerliEndpoint = await hre.ethers.getContractFactory("GoerliEndpoint");
    const goerliEndpoint = await GoerliEndpoint.deploy(
        "0x5a10ca57e07133AA5132eF29BA1EBf0096a302B0",
        "0xA10D0C6e04845A5e998d1936249A30563c553417"
    );
    await goerliEndpoint.deployed();
    console.log(
        `Goerli Endpoint: ${goerliEndpoint.address}`
    );
    await goerliEndpoint.setDarwiniaEndpoint(pangolin2Endpoint.address);

    ////////////////////////////////////////
    // Run
    //////////////////////////////////////// 
    const tx = await goerliEndpoint.dispatchOnParachain(
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
