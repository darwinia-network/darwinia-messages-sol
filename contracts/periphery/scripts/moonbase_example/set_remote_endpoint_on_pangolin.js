process.env.HARDHAT_NETWORK = "pangolin"
const hre = require("hardhat");

// on pangoro, set pangolin endpoint
async function main() {
    const endpoint_address = process.argv[2]
    const remote_endpoint_address = process.argv[3]
    const PangolinEndpoint = await hre.ethers.getContractFactory("PangolinEndpoint");
    const endpoint = await PangolinEndpoint.attach(endpoint_address);
    await endpoint.setRemoteEndpoint("0x70676c70", remote_endpoint_address); // PANGOLIN_PARACHAIN_CHAIN_ID

    const [A2, B] = await endpoint.getMessageOrigins();
    console.log(
        `pangolin_endpoint 32: ${A2}, pangolin_endpoint derived 32: ${B}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
