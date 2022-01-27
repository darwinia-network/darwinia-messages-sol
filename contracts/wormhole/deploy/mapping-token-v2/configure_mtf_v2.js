const fs = require('fs');

async function main() {
    var jsonpath = process.env.CONFIG;
    let jsonfile = fs.readFileSync(jsonpath);
    var configure = JSON.parse(jsonfile);
    const mtfSection = configure.mappingTokenFactory;
    const deployedMtfSection = configure.deployed.mappingTokenFactory;
    const deployedBackingSection = configure.deployed.backing;
    var mtf = await ethers.getContractAt("MappingTokenFactory", deployedMtfSection.proxy);
    // set guard
    if (deployedMtfSection.guard != "null") {
        console.log("update mtf guard");
        await mtf.updateGuard(deployedMtfSection.guard);
    }
    // addInboundLane
    console.log("add inboundlane for mtf");
    await mtf.addInboundLane(deployedBackingSection.proxy, mtfSection.inBoundLane);
    // addOutBoundLane
    console.log("add outboundlane for mtf");
    await mtf.addOutBoundLane(mtfSection.outBoundLane);
    // setTokenContractLogic
    console.log("set mapping token logic address");
    await mtf.setTokenContractLogic(0, configure.deployed.erc20);
}
 
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
});
