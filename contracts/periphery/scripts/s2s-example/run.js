const hre = require("hardhat");

// Dapp `Caller` on Pangolin will call `Callee` on Pangoro
// 
// Deployed example:
// Caller: 0x308f61D8a88f010146C4Ec15897ABc1EFc57c80a
// Callee: 0xe13084f8fF65B755E37d95F49edbD49ca26feE13
async function main() {
    // Output the sum property of Callee if there is only one argument
    if (process.argv[2]) {
        if (!process.argv[3]) {
            const calleeAddress = process.argv[2];

            hre.changeNetwork("pangoro");
            const Callee = await hre.ethers.getContractFactory("Callee");
            const callee = Callee.attach(calleeAddress);

            console.log(`The callee.sum is ${await callee.sum()}`);
        } else {
            const callerAddress = process.argv[2];
            const calleeAddress = process.argv[3];

            hre.changeNetwork("pangolin");
            const Caller = await hre.ethers.getContractFactory("Caller");
            const caller = Caller.attach(callerAddress);
            const PangolinEndpoint = await hre.ethers.getContractFactory("PangolinEndpoint");
            const pangolinEndpoint = PangolinEndpoint.attach(await caller.endpointAddress());
            const fee = pangolinEndpoint.fee();
            const tx = await caller.remoteAdd(
                calleeAddress,
                {
                    value: fee
                }
            )
            console.log(`tx: ${(await tx.wait()).transactionHash}`)
        }
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
