const utils = require("./utils");
const hre = require("hardhat");

async function main() {
  const pangolin2EndpointAddress = process.argv[2];

  hre.changeNetwork("pangolinDev")
  await utils.tractPangolin2EndpointEvents(pangolin2EndpointAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
