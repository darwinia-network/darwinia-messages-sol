process.env.HARDHAT_NETWORK = "pangolin";
const hre = require("hardhat");

// Dapp `Caller` on Pangolin will call `Callee` on Pangoro
async function main() {
    const Caller = await hre.ethers.getContractFactory("Caller");
    const caller = Caller.attach("0xA78aBD4CDAbCAf1A3Ae3F9105195E2c05810EE6E");

    const calleeAddress = "0xf6B8A7C7B82E3Bb3551393931d71987908bF486f";
    const tx = await caller.remoteAdd(
        calleeAddress,
        {
            value: hre.ethers.utils.parseEther("0.1")
        }
    )
    console.log(`tx: ${(await tx.wait()).transactionHash}`)
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
