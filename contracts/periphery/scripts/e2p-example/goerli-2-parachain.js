const hre = require("hardhat");

async function main() {
    ////////////////////////////////////////
    // Deploy
    ////////////////////////////////////////
    // PANGOLIN ENDPOINT
    // -------------
    hre.changeNetwork("pangolinDev");
    const Pangolin2Endpoint = await hre.ethers.getContractFactory("Pangolin2Endpoint");
    const pangolin2Endpoint = await Pangolin2Endpoint.deploy();
    await pangolin2Endpoint.deployed();
    console.log(
        `Pangolin Endpoint: ${pangolin2Endpoint.address}`
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
    await goerliEndpoint.setDarwiniaEndpoint(pangolin2Endpoint.address);
    console.log(
        `GoerliEndpoint knowns Pangolin2Endpoint.`
    );

    // Caller2
    const Caller2 = await hre.ethers.getContractFactory("Caller2");
    const caller2 = await Caller2.deploy(goerliEndpoint.address);
    await caller2.deployed();
    console.log(
        `Caller: ${caller2.address}`
    );

    ////////////////////////////////////////
    // Run
    ////////////////////////////////////////
    const fee = await goerliEndpoint.fee();
    const tx = await caller2.remoteAdd(
        "0x591f", // dest paraid
        "0x0a070c313233", // calldata
        5000000000, // weight
        20000000000000000000, // fungible
        {
            value: fee // market fee to pangolin
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
