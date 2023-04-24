const hre = require("hardhat");

// Deploy and connect endpoint on Pangolin and Pangoro
async function main() {
    // PANGOLIN
    // -------------
    hre.changeNetwork("pangolin");
    // Deploy endpoint on Pangolin
    const PangolinEndpoint = await hre.ethers.getContractFactory("PangolinEndpoint");
    const pangolinEndpoint = await PangolinEndpoint.deploy();
    await pangolinEndpoint.deployed();
    console.log(
        `Pangolin Endpoint: ${pangolinEndpoint.address}`
    );

    // Deploy `Caller` on Pangolin
    const Caller = await hre.ethers.getContractFactory("Caller");
    const caller = await Caller.deploy(pangolinEndpoint.address);
    await caller.deployed();
    console.log(
        `Caller: ${caller.address}`
    );

    // PANGORO
    // -------------
    hre.changeNetwork("pangoro");
    // Deploy endpoint on Pangoro
    const PangoroEndpoint = await hre.ethers.getContractFactory("PangoroEndpoint");
    const pangoroEndpoint = await PangoroEndpoint.deploy();
    await pangoroEndpoint.deployed();
    console.log(
        `Pangoro Endpoint: ${pangoroEndpoint.address}`
    );

    // Deploy `Callee` on Pangoro
    const Callee = await hre.ethers.getContractFactory("Callee");
    const callee = await Callee.deploy();
    await callee.deployed();
    console.log(
        `Callee: ${callee.address}`
    );

    // Let Pangoro endpoint know the Pangolin endpoint
    hre.changeNetwork("pangoro");
    const PANGOLIN_CHAIN_ID = 0x7061676c; // pagl
    await (await pangoroEndpoint.setRemoteEndpoint(PANGOLIN_CHAIN_ID, pangolinEndpoint.address)).wait();
    console.log(
        `PangoroEndpoint knowns PangolinEndpoint.`
    );

    // PANGOLIN
    // -------------
    hre.changeNetwork("pangolin");
    // Let Pangolin endpoint know the Pangoro endpoint
    const PANGORO_CHAIN_ID = 0x70616772; // pagr
    await (await pangolinEndpoint.setRemoteEndpoint(PANGORO_CHAIN_ID, pangoroEndpoint.address)).wait();
    console.log(
        `PangolinEndpoint knowns PangoroEndpoint.`
    );
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
