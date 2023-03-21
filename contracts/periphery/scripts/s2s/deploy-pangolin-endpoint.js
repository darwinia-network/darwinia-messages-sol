process.env.HARDHAT_NETWORK = "pangolin";
const hre = require("hardhat");

// Dapp `Caller` on Pangolin will call `Callee` on Pangoro
async function main() {
    // ////////////////////////////////////////
    // // Deploy
    // ////////////////////////////////////////
    // // ## Pangolin
    // // Deploy endpoint on Pangolin
    // const ToPangoroEndpoint = await hre.ethers.getContractFactory("ToPangoroEndpoint");
    // const pangolinEndpoint = await ToPangoroEndpoint.deploy();
    // await pangolinEndpoint.deployed();

    // console.log(
    //     `Pangolin Endpoint: ${pangolinEndpoint.address}`
    // );

    // // Deploy `Caller` on Pangolin
    // const Caller = await hre.ethers.getContractFactory("Caller");
    // const caller = await Caller.deploy(pangolinEndpoint.address);
    // await caller.deployed();

    // console.log(
    //     `Caller: ${caller.address}`
    // );

    // // ## Pangoro
    // hre.changeNetwork("pangoro");
    // // Deploy endpoint on Pangoro
    // const ToPangolinEndpoint = await hre.ethers.getContractFactory("ToPangolinEndpoint");
    // const pangoroEndpoint = await ToPangolinEndpoint.deploy();
    // await pangoroEndpoint.deployed();

    // console.log(
    //     `Pangoro Endpoint: ${pangoroEndpoint.address}`
    // );

    // // // Optional for this example
    // // const PANGOLIN_CHAIN_ID = 0x7061676c; // pagl
    // // await (await pangolinEndpoint.setRemoteEndpoint(PANGOLIN_CHAIN_ID, pangolinEndpoint.address)).wait();

    // // Deploy `Callee` on Pangoro
    // const Callee = await hre.ethers.getContractFactory("Callee");
    // const callee = await Callee.deploy();
    // await callee.deployed();

    // console.log(
    //     `Callee: ${callee.address}`
    // );

    // // ## Pangolin
    // // Let Pangolin endpoint know the Pangoro endpoint
    // const PANGORO_CHAIN_ID = 0x70616772; // pagr
    // await (await pangolinEndpoint.setRemoteEndpoint(PANGORO_CHAIN_ID, pangoroEndpoint.address)).wait();

    ////////////////////////////////////////
    // Remote call
    ////////////////////////////////////////
    const Caller = await hre.ethers.getContractFactory("Caller");
    const caller = Caller.attach("0xf6B8A7C7B82E3Bb3551393931d71987908bF486f");
    const Callee = await hre.ethers.getContractFactory("Caller");
    const callee = Callee.attach("0xae6538b36E50c98bf776626ec845e2128486b7A3");
    const tx = await caller.remoteAdd(
        callee.address,
        {
            value: hre.ethers.utils.parseEther("1")
        }
    )

    console.log(`tx: ${(await tx.wait()).transactionHash}`)
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
