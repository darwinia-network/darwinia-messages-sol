process.env.HARDHAT_NETWORK = "pangolin";
const hre = require("hardhat");

// Dapp `Caller` on Pangolin will call `Callee` on Pangoro
async function main() {
    const callerAddress = process.argv[2];
    const calleeAddress = process.argv[3];
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

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
