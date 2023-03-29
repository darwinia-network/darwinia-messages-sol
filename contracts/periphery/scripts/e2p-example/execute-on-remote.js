const hre = require("hardhat");

const utils = require("./utils.js");

async function main() {
    if (process.argv[2]) {
        if (!process.argv[3]) { // Output the sum property of Callee if there is only one argument
            hre.changeNetwork("pangolinDev");
            const calleeAddress = process.argv[2];
            const Callee2 = await hre.ethers.getContractFactory("Callee2");
            const callee2 = Callee2.attach(calleeAddress);
            console.log(`The callee2.sum is ${await callee2.sum()}`);
        } else { // Call remoteAdd
            const callerAddress = process.argv[2];
            const calleeAddress = process.argv[3];

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

            // Call remoteAdd
            const tx = await caller2.remoteAdd(
                calleeAddress,
                {
                    value: fee
                }
            )

            console.log(`https://goerli.etherscan.io/tx/${(await tx.wait()).transactionHash}`)

            await utils.checkSumOnPangolin2(calleeAddress, "Callee2")
        }
    }
}

const sleep = ms => new Promise(r => setTimeout(r, ms));

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
