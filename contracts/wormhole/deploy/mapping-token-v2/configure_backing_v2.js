const fs = require('fs');

async function main() {
    var jsonpath = process.env.CONFIG;
    let jsonfile = fs.readFileSync(jsonpath);
    var configure = JSON.parse(jsonfile);
    const backingSection = configure.backing;
    const deployedBackingSection = configure.deployed.backing;
    var backing = await ethers.getContractAt("Backing", deployedBackingSection.proxy);
    // set guard
    if (backing.guard != "null") {
        console.log("update guard for backing");
        await backing.updateGuard(deployedBackingSection.guard);
    }
    // addInboundLane
    console.log("add inboundlane for backing");
    await backing.addInboundLane(backingSection.inBoundLane);
    // addOutBoundLane
    console.log("add outboundlane for backing");
    await backing.addOutboundLane(backingSection.outBoundLane);
}
 
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
});
