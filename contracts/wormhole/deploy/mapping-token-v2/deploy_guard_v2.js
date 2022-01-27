var MappingTokenDeployer = require("./contract_deployer.js");
const fs = require('fs');

async function main() {
    /***************** this should be configured first *************/
    //const guards = ["0x1000000000000000000000000000000000000000"];
    //const threshold = 1;
    //const maxUnclaimableTime = 0;
    //const depositor = "0x0000000000000000000000000000000000000000";
    /***************************************************************/
    var jsonpath = process.env.CONFIG;
    let jsonfile = fs.readFileSync(jsonpath);
    var configure = JSON.parse(jsonfile);
    var guardSection = configure.guard;
    var deployedSection = configure.deployed;
    var who = process.env.DEPOSITOR;
    var depositor = who == "backing" ? deployedSection.backing.proxy : deployedSection.mappingTokenFactory.proxy;

    const guard = await MappingTokenDeployer.deployGuard(
        guardSection.guards,
        guardSection.threshold,
        guardSection.maxUnclaimableTime,
        depositor
    );
    console.log("deploy guard success", guard.address);

    deployedSection[who].guard = guard.address;
    let storeData = JSON.stringify(configure, null, 2);
    fs.writeFileSync(jsonpath, storeData);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
