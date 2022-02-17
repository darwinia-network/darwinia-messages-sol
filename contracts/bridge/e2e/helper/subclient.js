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

    await this.set_chain_committer()
  }

  async set_chain_committer() {
    const call = await this.api.tx.beefyGadget.setCommitmentContract(addresses.ChainMessageCommitter)
    const tx = await this.api.tx.sudo.sudo(call).signAndSend(this.alice)
    console.log(`Set chain committer tx submitted with hash: ${tx}`)
    const res = await this.api.query.beefyGadget.commitmentContract()
    console.log(`Get chain committer: ${res}`)
  }

  async relay_header(state_root) {
    const tx = await this.api.tx.bsc.setStateRoot(state_root).signAndSend(this.alice)
    // console.log(`Header relay tx submitted with hash: ${tx}`)
  }

  async block_header() {
    const header = await this.api.rpc.chain.getHeader()
    // console.log(`last block #${header.number} has hash ${header.hash}`)
    return header
  }

  async beefy_payload(block_number, block_hash) {
    const messageRoot = await this.chainMessageCommitter['commitment()']({ blockTag: block_number })
    const network = "0x50616e676f6c696e000000000000000000000000000000000000000000000000"
    const next_authority_set = await this.api.query.mmrLeaf.beefyNextAuthorities.at(block_hash)
    const mmr = await this.api.query.mmr.rootHash.at(block_hash)
    return {
        network,
        mmr: mmr.toHex(),
        messageRoot,
        nextValidatorSet: next_authority_set.toJSON()
    }
  }

  async beefy_block() {
    // const hash = await this.api.rpc.chain.getFinalizedHead()
    // const hash = await this.api.rpc.beefy.getFinalizedHead()
    const hash = '0x80beb0a11463c73e97be98a578ffcff1a1560065ec47a9b7acd50bd0ef75eb4c';
    console.log(`Finalized head hash ${hash}`)
    const block = await this.api.rpc.chain.getBlock(hash)
    console.log(`Finalized block #${block.block.header.number} has ${block}`)
    return block
  }

}

module.exports.SubClient = SubClient
