var ProxyDeployer = require("../utils/proxy_deployer.js");
var MappingTokenDeployer = require("./contract_deployer.js");

async function main() {
    /***************** this should be configured first *************/
    const bridgedChainPosition = 1;
    const remoteMappingTokenFactoryAddress = "0x0000000000000000000000000000000000000000";
    const feeMarketAddress = "0x0000000000000000000000000000000000000000";
    const localChainName = "bsc";
    /***************************************************************/

    const proxyAdmin = await ProxyDeployer.deployProxyAdmin();
    console.log("deploy proxy admin for backing success", proxyAdmin.address);
    const backing = await MappingTokenDeployer.deployBacking(
        proxyAdmin.address,
        bridgedChainPosition,
        remoteMappingTokenFactoryAddress,
        feeMarketAddress,
        localChainName
    );
    console.log("deploy backing success", backing.address);

    // after deployed, we should add at least one inboundLane and outboundLane
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
