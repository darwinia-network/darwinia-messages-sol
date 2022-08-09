const EthClient = require('./ethclient').EthClient
const SubClient = require('./subclient').SubClient
const Bridge    = require('./bridge').Bridge
const Eth2Client = require('./eth2client').Eth2Client

const target  = process.env.TARGET || 'local'
const INFURA_KEY = process.env.INFURA_KEY
const MORALIS_KEY = process.env.MORALIS_KEY

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
  evm_eth_addresses = require("../../bin/addr/test/sepolia.json")
  evm_bsc_addresses = require("../../bin/addr/test/bsctest.json")
  dvm_addresses = require("../../bin/addr/test/pangoro.json")

  // evm_eth_endpoint = "https://rpc.sepolia.org"
  evm_eth_endpoint = "http://127.0.0.1:8545"
  // evm_bsc_endpoint = `https://speedy-nodes-nyc.moralis.io/${MORALIS_KEY}/bsc/testnet/archive`
  evm_bsc_endpoint = "https://data-seed-prebsc-1-s1.binance.org:8545"
  dvm_endpoint = "https://pangoro-rpc.darwinia.network"
  sub_endpoint = "wss://pangoro-rpc.darwinia.network"
  // beacon_endpoint = "https://lodestar-kiln.chainsafe.io"
  beacon_endpoint = "http://127.0.0.1:5052"

  ns_eth = 'sepolia'
  ns_bsc = 'bsctest'
  ns_dvm = 'pangoro'
}

const addr1 = "0x3DFe30fb7b46b99e234Ed0F725B5304257F78992"
const addr2 = "0xB3c5310Dcf15A852b81d428b8B6D5Fb684300DF9"
const addr3 = "0xf4F07AAe298E149b902993B4300caB06D655f430"
const addrs = [addr1, addr2, addr3]

const priv1 = "d2f4e4eaf19bc75ebb1d8d9f7399fbb554ce92c5c2cb04610651db9860b080b3"
const priv2 = "9438704f5bd45bbcfc59e6989db378112db0c070e703249b32f0f298b753313e"
const priv3 = "482e54d8bb063ffa1f39a66f48235eac0e13988bede00be37728c7eafb762b32"
const wallets = [
  new ethers.Wallet(priv1),
  new ethers.Wallet(priv2),
  new ethers.Wallet(priv3),
]

const fees = [
  ethers.utils.parseEther("10"),
  ethers.utils.parseEther("20"),
  ethers.utils.parseEther("30")
]

async function bootstrap() {
  const ethClient = new EthClient(evm_eth_endpoint)
  const bscClient = new EthClient(evm_bsc_endpoint)
  const subClient = new SubClient(dvm_endpoint, sub_endpoint)
  const eth2Client = new Eth2Client(beacon_endpoint)
  const bridge = new Bridge(ethClient, bscClient, eth2Client, subClient)
  await ethClient.init(wallets, fees, evm_eth_addresses, ns_dvm)
  await bscClient.init(wallets, fees, evm_bsc_addresses, ns_dvm)
  await subClient.init(wallets, fees, dvm_addresses, ns_eth, ns_bsc)
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
