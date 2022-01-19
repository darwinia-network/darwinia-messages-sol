var MappingTokenDeployer = require("./contract_deployer.js");

async function main() {
    /***************** this should be configured first *************/
    const guards = ["0x1000000000000000000000000000000000000000"];
    const threshold = 1;
    const maxUnclaimableTime = 0;
    const depositor = "0x0000000000000000000000000000000000000000";
    /***************************************************************/

    const guard = await MappingTokenDeployer.deployGuard(
        guards,
        threshold,
        maxUnclaimableTime,
        depositor
    );
    console.log("deploy guard success", guard.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
