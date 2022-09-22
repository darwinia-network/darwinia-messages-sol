process.env.HARDHAT_NETWORK = "moonbase"
const hre = require("hardhat");

async function main() {
    const Callee = await hre.ethers.getContractFactory("Callee");
    const callee = await Callee.deploy();

    await callee.deployed();

    console.log(
        `${callee.address}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
