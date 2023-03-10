const EthClient = require('./ethclient').EthClient
const SubClient = require('./subclient').SubClient
const Bridge    = require('./bridge').Bridge
const Eth2Client = require('./eth2client').Eth2Client

const target  = process.env.TARGET || 'local'
const INFURA_KEY = process.env.INFURA_KEY
const ALCHEMY_KEY = process.env.ALCHEMY_KEY
const MORALIS_KEY = process.env.MORALIS_KEY

const PRIV1 = process.env.PRIV1
const PRIV2 = process.env.PRIV2
const PRIV3 = process.env.PRIV3

let evm_eth_addresses, evm_bsc_addresses, dvm_addresses, evm_endpoint, dvm_endpoint, sub_endpoint
let ns_eth, ns_bsc, ns_dvm
if (target == 'local') {
  evm_eth_addresses = require("../../bin/addr/local/evm-eth2.json")
  evm_bsc_addresses = require("../../bin/addr/local/evm-bsc.json")
  dvm_addresses = require("../../bin/addr/local/dvm.json")

  evm_eth_endpoint = "http://127.0.0.1:8545"
  evm_bsc_endpoint = "http://127.0.0.1:8545"
  dvm_endpoint = "http://127.0.0.1:9933"
  sub_endpoint = "ws://127.0.0.1:9944"
  beacon_endpoint = "http://127.0.0.1:5052"
  // evm_endpoint = "http://192.168.2.100:8545"
  // dvm_endpoint = "http://192.168.2.100:10033"
  // sub_endpoint = "ws://192.168.2.100:10044"
  // beacon_endpoint = "http://127.0.0.1:5052"

  ns_eth = 'evm-eth2'
  ns_bsc = 'evm-bsc'
  ns_dvm = 'dvm'
} else if (target == 'test') {
  evm_eth_addresses = require("../../bin/addr/test/goerli.json")
  evm_bsc_addresses = require("../../bin/addr/test/bsctest.json")
  dvm_addresses = require("../../bin/addr/test/pangolin.json")

  evm_eth_endpoint = `https://eth-goerli.g.alchemy.com/v2/${ALCHEMY_KEY}`
  // evm_eth_endpoint = "http://127.0.0.1:8545"
  // evm_bsc_endpoint = `https://speedy-nodes-nyc.moralis.io/${MORALIS_KEY}/bsc/testnet/archive`
  evm_bsc_endpoint = "https://data-seed-prebsc-1-s1.binance.org:8545"
  // dvm_endpoint = "https://pangoro-rpc.darwinia.network"
  dvm_endpoint = "http://192.168.132.159:9933"
  sub_endpoint = "ws://192.168.132.159:9944"
  // sub_endpoint = "wss://pangoro-rpc.darwinia.network"
  // beacon_endpoint = "http://unstable.prater.beacon-api.nimbus.team"
  beacon_endpoint = "https://lodestar-goerli.chainsafe.io"

  ns_eth = 'goerli'
  ns_bsc = 'bsctest'
  ns_dvm = 'pangoro'
}

const wallets = [
  new ethers.Wallet(PRIV1),
  new ethers.Wallet(PRIV2),
  new ethers.Wallet(PRIV3),
]

const addrs = wallets.map((w) => w.address)

const sub_fees = [
  ethers.utils.parseEther("10"),
  ethers.utils.parseEther("20"),
  ethers.utils.parseEther("30")
]

const eth_fees = [
  ethers.utils.parseEther("0.0001"),
  ethers.utils.parseEther("0.0002"),
  ethers.utils.parseEther("0.0003")
]

const bsc_fees = [
  ethers.utils.parseEther("0.01"),
  ethers.utils.parseEther("0.02"),
  ethers.utils.parseEther("0.03")
]

async function bootstrap() {
  const ethClient = new EthClient(evm_eth_endpoint)
  const bscClient = new EthClient(evm_bsc_endpoint)
  const subClient = new SubClient(dvm_endpoint, sub_endpoint)
  const eth2Client = new Eth2Client(beacon_endpoint)
  const bridge = new Bridge(ethClient, bscClient, eth2Client, subClient)
  await ethClient.init(wallets, eth_fees, evm_eth_addresses, ns_dvm)
  // await bscClient.init(wallets, bsc_fees, evm_bsc_addresses, ns_dvm)
  await subClient.init(wallets, sub_fees, dvm_addresses, ns_eth, ns_bsc)
  return {
    ethClient,
    bscClient,
    eth2Client,
    subClient,
    bridge
  }
}

module.exports = {
  addrs,
  wallets,
  bootstrap
}
