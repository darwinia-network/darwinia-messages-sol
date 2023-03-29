const hre = require("hardhat");

async function main() {
    // PANGOLIN ENDPOINT
    // -------------
    hre.changeNetwork("pangolinDev");
    const Pangolin2Endpoint = await hre.ethers.getContractFactory("Pangolin2Endpoint");
    const pangolin2Endpoint = await Pangolin2Endpoint.deploy();
    await pangolin2Endpoint.deployed();
    console.log(
        `Pangolin2Endpoint: ${pangolin2Endpoint.address}`
    );

    // GOERLI ENDPOINT
    // -------------
    hre.changeNetwork("goerli");
    const GoerliEndpoint = await hre.ethers.getContractFactory("GoerliEndpoint");
    const goerliEndpoint = await GoerliEndpoint.deploy();
    await goerliEndpoint.deployed();
    console.log(
        `Goerli Endpoint: ${goerliEndpoint.address}`
    );

    // Make GoerliEndpoint known Pangolin2Endpoint
    await goerliEndpoint.setRemoteEndpoint(pangolin2Endpoint.address);

    // DAPP
    // -------------
    const Caller2 = await hre.ethers.getContractFactory("Caller2");
    const caller2 = await Caller2.deploy(goerliEndpoint.address);
    await caller2.deployed();
    console.log(
        `Caller2: ${caller2.address}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
