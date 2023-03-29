const hre = require("hardhat");

const utils = require("./utils.js");

async function main() {
    const callerAddress = process.argv[2];
    const pangolin2EndpointAddress = process.argv[3];
    await remoteRemarkWithEvent(callerAddress);
}

async function remoteRemarkWithEvent(callerAddress) {
    hre.changeNetwork("goerli");

    const Caller2 = await hre.ethers.getContractFactory("Caller2");
    const caller2 = Caller2.attach(callerAddress);
    console.log(
        `Goerli Endpoint: ${await caller2.endpointAddress()}`
    );

    // Get market fee
    const GoerliEndpoint = await hre.ethers.getContractFactory("GoerliEndpoint");
    const goerliEndpoint = GoerliEndpoint.attach(await caller2.endpointAddress());
    const fee = await goerliEndpoint.fee();
    console.log(
        `Market fee: ${fee}`
    );

    // Remote dispatch `remark with event`
    const tx = await caller2.remoteRemarkWithEvent(
        {
            value: fee
        }
    )

    console.log(`https://goerli.etherscan.io/tx/${(await tx.wait()).transactionHash}`)
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
