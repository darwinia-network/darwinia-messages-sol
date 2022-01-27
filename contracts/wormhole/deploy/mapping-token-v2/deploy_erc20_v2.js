var MappingTokenDeployer = require("./contract_deployer.js");
const fs = require('fs');

async function main() {
    var jsonpath = process.env.CONFIG;
    let jsonfile = fs.readFileSync(jsonpath);
    var configure = JSON.parse(jsonfile);
    const erc20Logic = await MappingTokenDeployer.deployMappingErc20Logic();
    console.log("deploy mapping erc20 logic success", erc20Logic.address);
    configure.deployed.erc20 = erc20Logic.address;
    let storeData = JSON.stringify(configure, null, 2);
    fs.writeFileSync(jsonpath, storeData);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
