var ProxyDeployer = require("../utils/proxy_deployer.js");
var MappingTokenDeployer = require("./contract_deployer.js");
const fs = require('fs');

async function main() {
    /***************** this should be configured first *************/
    //const bridgedChainPosition = 1;
    //const remoteMappingTokenFactoryAddress = "0x0000000000000000000000000000000000000000";
    //const feeMarketAddress = "0x0000000000000000000000000000000000000000";
    //const localChainName = "bsc";
    /***************************************************************/
    // remote mapping token factory must be deployed first
    var jsonpath = process.env.CONFIG;
    let jsonfile = fs.readFileSync(jsonpath);
    var configure = JSON.parse(jsonfile);
    var backingConfig = configure.backing;
    const deployedSection = configure.deployed;

    const proxyAdmin = await ProxyDeployer.deployProxyAdmin();
    console.log("deploy proxy admin for backing success", proxyAdmin.address);
    const backing = await MappingTokenDeployer.deployBacking(
        proxyAdmin.address,
        backingConfig.bridgedChainPosition,
        deployedSection.mappingTokenFactory.proxy,
        backingConfig.feeMarketAddress,
        backingConfig.localChainName
    );
    console.log("deploy backing success", backing.logic.address, backing.proxy.address);

    // generate address
    deployedSection.backing.proxyAdmin = proxyAdmin.address
    deployedSection.backing.logic = backing.logic.address
    deployedSection.backing.proxy = backing.proxy.address
    let storeData = JSON.stringify(configure, null, 2);
    fs.writeFileSync(jsonpath, storeData);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
