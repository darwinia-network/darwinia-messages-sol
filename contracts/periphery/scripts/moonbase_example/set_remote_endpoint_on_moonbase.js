process.env.HARDHAT_NETWORK = "moonbase"
const hre = require("hardhat");

// on pangoro, set pangolin endpoint
async function main() {
    const endpoint_address = process.argv[2]
    const remote_endpoint_address = process.argv[3]

    const MoonbaseEndpoint = await hre.ethers.getContractFactory("MoonbaseEndpoint");
    const endpoint = await MoonbaseEndpoint.attach(endpoint_address);
    
    const tx = await endpoint.setRemoteEndpoint("0x7061676c", "0x00000839", remote_endpoint_address); // PANGOLIN_CHAIN_ID
    await tx.wait()

    console.log("### MOONBASE > PANGOLIN: ")
    const moonbaseEndpoint_A2 = await endpoint.getMessageOriginOnPangolinParachain();
    console.log(
        `MOONBASE_ENDPOINT 32(A2)       : ${moonbaseEndpoint_A2} <- manual deposit\n`
    );

    console.log("### PANGOLIN > MOONBASE: ")
    const A2 = await endpoint.darwiniaEndpointAccountId32();
    console.log(
        `PANGOLIN_ENDPOINT 32(A2)       : ${A2}`
    );
    const B = await endpoint.darwiniaEndpointAccountId32Derived();
    console.log(
        `PANGOLIN_ENDPOINT DERIVED 32(B): ${B} <- manual deposit`
    );
    const C = await endpoint.darwiniaEndpointAddressDerived();
    console.log(
        `PANGOLIN_ENDPOINT DERIVED 20(C): ${C}\n`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});