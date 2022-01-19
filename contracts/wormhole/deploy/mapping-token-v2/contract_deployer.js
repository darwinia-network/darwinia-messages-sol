var ProxyDeployer = require("../utils/proxy_deployer.js");

var MappingTokenDeployer = {
    deployBacking: async function(proxyAdminAddr, bridgeChainPosition, remoteMappingTokenFactoryAddress, feeMarketAddress, chainName) {
        console.log("deploy backing contract, it's a proxy contract");
        const backingContract = await ethers.getContractFactory("Backing");
        const backingLogic = await backingContract.deploy();
        console.log("deploy backing logic", backingLogic.address);
        return await ProxyDeployer.deployProxyContract(
            proxyAdminAddr,
            backingContract,
            backingLogic.address,
            [bridgeChainPosition, remoteMappingTokenFactoryAddress, feeMarketAddress, chainName]
        );
    },
    deployMappingTokenFactory: async function(proxyAdminAddr, feeMarketAddress) {
        console.log("deploy mapping token factory contract, it's a proxy contract");
        const mtfContract = await ethers.getContractFactory("MappingTokenFactory");
        const mtfLogic = await mtfContract.deploy();
        console.log("deploy mtf logic", mtfLogic.address);
        return await ProxyDeployer.deployProxyContract(
            proxyAdminAddr,
            mtfContract,
            mtfLogic.address,
            [feeMarketAddress]
        );
    },
    deployGuard: async function(guards, threshold, maxUnclaimableTime, depositor) {
        console.log("deploy guard");
        const guardContract = await ethers.getContractFactory("Guard");
        const guard = await guardContract.deploy(guards, threshold, maxUnclaimableTime, depositor);
        return guard;
    },
    deployMappingErc20Logic: async function() {
        console.log("deploy mapping erc20 contract");
        const erc20Contract = await ethers.getContractFactory("MappingERC20");
        const erc20Logic = await erc20Contract.deploy();
        return erc20Logic;
    },
}

module.exports = MappingTokenDeployer
