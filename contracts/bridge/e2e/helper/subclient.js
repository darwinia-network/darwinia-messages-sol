let { ApiPromise, WsProvider, Keyring } = require('@polkadot/api');
const addresses = require("../../bin/addr/local-dvm.json")
const { EvmClient } = require('./evmclient')

/**
 * The Substrate client for Bridge interaction
 */
class SubClient extends EvmClient {

  constructor(http_endpoint, ws_endpoint) {
    super(http_endpoint)
    this.sub_provider = new WsProvider(ws_endpoint)
  }

  async init(wallets, fees) {
    await super.init(addresses, wallets, fees)

    this.api = await ApiPromise.create({
      provider: this.sub_provider
    })
    this.keyring = new Keyring({ type: 'sr25519' });
    this.alice = this.keyring.addFromUri('//Alice', { name: 'Alice' });

    const ChainMessageCommitter = await artifacts.readArtifact("ChainMessageCommitter");
    this.chainMessageCommitter = new ethers.Contract(addresses.ChainMessageCommitter, ChainMessageCommitter.abi, this.provider)

    const LaneMessageCommitter = await artifacts.readArtifact("LaneMessageCommitter");
    this.laneMessageCommitter = new ethers.Contract(addresses.LaneMessageCommitter, LaneMessageCommitter.abi, this.provider)

    const BSCLightClient = await artifacts.readArtifact("BSCLightClient")
    const lightClient = new ethers.Contract(addresses.BSCLightClient, BSCLightClient.abi, this.provider)

    this.lightClient = lightClient.connect(this.signer)
  }

  async relay_header(state_root) {
    const tx = await this.api.tx.bsc.setStateRoot(state_root).signAndSend(this.alice)
    console.log(`Header relay tx submitted with hash: ${tx}`)
  }

  async block_header() {
    const header = await this.api.rpc.chain.getHeader();
    console.log(`last block #${header.number} has hash ${header.hash}`);
    return header
  }

}

module.exports.SubClient = SubClient;
