/**
 * Deploys smart contracts
 * 
 */
//const Web3 = require('web3');
const fs = require("fs");
var readlineSync = require('readline-sync');

var m = {
    deploy: async function(web3, bin, abi, args) {
        console.log('start to deploy contract wait...');
        const bytecode = fs.readFileSync(bin).toString().trim();
        const abistream = fs.readFileSync(abi).toString();

        const walletAddress = web3.eth.accounts.wallet[0].address;
        const jsonabi = JSON.parse(abistream);
        const contract = new web3.eth.Contract(jsonabi);

        const deployment = await contract.deploy({
            data: bytecode, arguments: args
        }).send({
            from: walletAddress,
            gasLimit: web3.utils.toHex(6000000),
            gasPriceLimit: web3.utils.toHex(60000000000)
        });
        console.log('contract was successfully deployed!');
        console.log(`The contract can be interfaced with at this address: ${deployment.options.address}`);
        return deployment.options.address
    },

    deployJson: async function(web3, jsonfile, args) {
        console.log('start to deploy contract with json file');
        const walletAddress = web3.eth.accounts.wallet[0].address;
        const abi = jsonfile.abi;
        const bytecode = jsonfile.bytecode;
        const contract = new web3.eth.Contract(abi);
        const deployment = await contract.deploy({
            data: bytecode, arguments: args
        }).send({
            from: walletAddress,
            gasLimit: web3.utils.toHex(6000000),
            gasPriceLimit: web3.utils.toHex(60000000000)
        });
        console.log('contract was successfully deployed!');
        console.log(`The contract can be interfaced with at this address: ${deployment.options.address}`);
        return deployment.options.address
    },

    callData: function(web3, jsonabi, address, func, ...params) {
        var contract = new web3.eth.Contract(jsonabi, address);
        return contract.methods.initialize(...params).encodeABI();
    },

    confirmInfo: function() {
        const confirmed = readlineSync.question("Be sure to deploy(y/N)?");
        if (confirmed != "y") {
            console.log("the contract deployment canceled");
            return false;
        }
        return true;
    }
}

module.exports = m


