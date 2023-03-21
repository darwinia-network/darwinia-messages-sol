process.env.HARDHAT_NETWORK = "pangolin"
const hre = require("hardhat");

async function main() {
  const DarwiniaEndpoint = await hre.ethers.getContractFactory("DarwiniaEndpoint");
  const endpoint = await DarwiniaEndpoint.deploy(
    "0x2100",
    "0xe520",
    "0xbA6c0608f68fA12600382Cd4D964DF9f090AA5B5",
    "0x3553b673A47E66482b6eCFAE5bfc090Cc7eeEd27"
  );
  await endpoint.deployed();

  console.log(
    `Darwinia Endpoint: ${endpoint.address}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
