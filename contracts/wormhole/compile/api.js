const fs = require("fs");

var api = {
    createContractObj: function(web3, abi, addr) {
        const abistream = fs.readFileSync(abi).toString();
        const jsonabi = JSON.parse(abistream);
        return new web3.eth.Contract(jsonabi, addr);
    },
	call: async function(contract, name, ...info) {
		const rest = await contract.methods[name](...info).call();
		console.log(`call ${name}: ${rest}`);
		return rest
	},
	send: async function(web3, contract, method, address, ...info) {
		let result = await contract.methods[method](
			...info
		).send({
			from: address,
			gasLimit: web3.utils.toHex(3000000),
			gasPrice: web3.utils.toHex(20000000000),
		});
		console.log(result.transactionHash);
	}
}

module.exports = api

