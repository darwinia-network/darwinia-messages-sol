process.env.HARDHAT_NETWORK = "moonbase"
const hre = require("hardhat");

// on pangoro, set pangolin endpoint
async function main() {
    const endpoint_address = process.argv[2]
    const remote_endpoint_address = process.argv[3]

    const MoonbaseEndpoint = await hre.ethers.getContractFactory("MoonbaseEndpoint");
    const moonbaseEndpoint = await MoonbaseEndpoint.attach(endpoint_address);
    
    const tx = await moonbaseEndpoint.setTargetEndpoint("0x7061676c", "0x00000839", remote_endpoint_address); // PANGOLIN_CHAIN_ID
    await tx.wait()

    const moonbaseEndpoint_A2 = await moonbaseEndpoint.getDerivedAccountId();
    console.log(
        `MOONBASE_ENDPOINT 32(A2)       : ${moonbaseEndpoint_A2} <- manual deposit\n`
    );

    // const C = await moonbaseEndpoint.derivedMessageSender();
    // console.log(
    //     `PANGOLIN_ENDPOINT DERIVED 20(C): ${C}\n`
    // );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
