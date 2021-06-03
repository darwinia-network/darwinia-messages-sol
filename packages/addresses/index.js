const addresses = require("./addresses.json")

function getContractAddresses(chainId) {
    if (addresses[chainId] === undefined) {
        throw new Error(`Unknown chain id (${chainId}). No known contracts have been deployed on this chain.`);
    }
    return addresses[chainId];
}

module.exports = {
  getContractAddresses
}
