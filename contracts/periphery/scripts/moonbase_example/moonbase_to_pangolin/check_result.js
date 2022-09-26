process.env.HARDHAT_NETWORK = "pangolin"
const hre = require("hardhat");

async function main() {
    const callee_adderss = process.argv[2]
    console.log(`callee: ${callee_adderss}`);
    const callee = await hre.ethers.getContractAt("Callee", callee_adderss);

    const sum = await callee.sum();
    console.log(sum)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
