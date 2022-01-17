const EthClient = require('./ethclient').EthClient
const SubClient = require('./subclient').SubClient

// const evm_endpoint = "http://127.0.0.1:8545"
// const dvm_endpoint = "http://127.0.0.1:9933"
const evm_endpoint = "http://192.168.2.100:8545"
const dvm_endpoint = "http://192.168.2.100:9933"

async function bootstrap() {
  const ethClient = new EthClient(evm_endpoint)
  const subClient = new SubClient(dvm_endpoint)
  await ethClient.init()
  await subClient.init()
  return { ethClient, subClient }
}

module.exports = {
  bootstrap
}
