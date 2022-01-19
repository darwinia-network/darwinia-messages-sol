var ProxyDeployer = {
    getInitializerData: function(
        contractInterface,
        args,
        initializer,
    ) {
        try {
            const fragment = contractInterface.getFunction(initializer);
            return contractInterface.encodeFunctionData(fragment, args);
        } catch (e) {
            throw e;
        }
    },
    deployProxyAdmin: async function() {
        const proxyAdminContract = await ethers.getContractFactory("ProxyAdmin");
        const proxyAdmin = await proxyAdminContract.deploy();
        return proxyAdmin;
    },
    deployProxyContract: async function(proxyAdminAddr, logicFactory, logicAddress, args) {
        const calldata = ProxyDeployer.getInitializerData(logicFactory.interface, args, "initialize");
        const proxyContract = await ethers.getContractFactory("TransparentUpgradeableProxy");
        const proxy = await proxyContract.deploy(logicAddress, proxyAdminAddr, calldata)
        return proxy;
    }
}

module.exports = ProxyDeployer
