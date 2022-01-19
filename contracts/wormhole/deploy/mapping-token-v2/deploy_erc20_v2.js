var MappingTokenDeployer = require("./contract_deployer.js");

async function main() {
    const erc20Logic = await MappingTokenDeployer.deployMappingErc20Logic();
    console.log("deploy mapping erc20 logic success", erc20Logic.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
