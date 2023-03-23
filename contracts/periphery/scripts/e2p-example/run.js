const hre = require("hardhat");

// Dapp `Caller` on Pangolin will call `Callee` on Pangoro
async function main() {
    const callerAddress = process.argv[2];
    const Caller2 = await hre.ethers.getContractFactory("Caller2");
    const caller2 = Caller2.attach(callerAddress);

    hre.changeNetwork("goerli");
    const GoerliEndpoint = await hre.ethers.getContractFactory("GoerliEndpoint");
    const goerliEndpoint = GoerliEndpoint.attach(await caller2.endpointAddress());
    console.log(
        `Goerli Endpoint: ${goerliEndpoint.address}`
    );

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

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
