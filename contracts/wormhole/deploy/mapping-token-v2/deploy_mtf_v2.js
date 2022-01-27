var ProxyDeployer = require("../utils/proxy_deployer.js");
var MappingTokenDeployer = require("./contract_deployer.js");
const fs = require('fs');

async function main() {
    /***************** this should be configured first *************/
    //const feeMarketAddress = "0x0000000000000000000000000000000000000000";
    /***************************************************************/

    /***************** read from configure file *******************/
    var jsonpath = process.env.CONFIG;
    let jsonfile = fs.readFileSync(jsonpath);
    var configure = JSON.parse(jsonfile);
    const feeMarketAddress = configure.mappingTokenFactory.feeMarketAddress;
    const deployedSection = configure.deployed;

    const proxyAdmin = await ProxyDeployer.deployProxyAdmin();
    console.log("deploy proxy admin for mtf success", proxyAdmin.address);
    const mtf = await MappingTokenDeployer.deployMappingTokenFactory(
        proxyAdmin.address,
        feeMarketAddress,
    );
    console.log("deploy mapping token factory success", mtf.logic.address, mtf.proxy.address);

    // generate address
    deployedSection.mappingTokenFactory.proxyAdmin = proxyAdmin.address
    deployedSection.mappingTokenFactory.logic = mtf.logic.address
    deployedSection.mappingTokenFactory.proxy = mtf.proxy.address
    let storeData = JSON.stringify(configure, null, 2);
    fs.writeFileSync(jsonpath, storeData);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
