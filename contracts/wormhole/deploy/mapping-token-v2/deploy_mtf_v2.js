var ProxyDeployer = require("../utils/proxy_deployer.js");
var MappingTokenDeployer = require("./contract_deployer.js");

async function main() {
    /***************** this should be configured first *************/
    const feeMarketAddress = "0x0000000000000000000000000000000000000000";
    /***************************************************************/

    const proxyAdmin = await ProxyDeployer.deployProxyAdmin();
    console.log("deploy proxy admin for mtf success", proxyAdmin.address);
    const mtf = await MappingTokenDeployer.deployMappingTokenFactory(
        proxyAdmin.address,
        feeMarketAddress,
    );
    console.log("deploy mapping token factory success", mtf.address);

    // after deployed, we should add remote backing inbould if remote is accepted and outbound
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
