process.env.HARDHAT_NETWORK = "moonbase"
const hre = require("hardhat");

// on pangoro, set pangolin endpoint
async function main() {
    const endpoint_address = process.argv[2]
    const remote_endpoint_address = process.argv[3]

    const MoonbaseEndpoint = await hre.ethers.getContractFactory("MoonbaseEndpoint");
    const endpoint = await MoonbaseEndpoint.attach(endpoint_address);
    
    await endpoint.setRemoteEndpoint("0x7061676c", "0x00000839", remote_endpoint_address); // PANGOLIN_CHAIN_ID

    const messageOrigin32 = await endpoint.getMessageOrigin32();
    console.log(
        `moonbase_endpoint 32: ${messageOrigin32}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});