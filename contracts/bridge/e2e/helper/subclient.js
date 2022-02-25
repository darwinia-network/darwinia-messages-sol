let { ApiPromise, WsProvider, Keyring } = require('@polkadot/api');
const { EvmClient } = require('./evmclient')
const { encodeNextAuthoritySet } = require('./encode')

/**
 * The Substrate client for Bridge interaction
 */
class SubClient extends EvmClient {

  constructor(http_endpoint, ws_endpoint) {
    super(http_endpoint)
    this.sub_provider = new WsProvider(ws_endpoint)
  }

  async init(wallets, fees, addresses) {
    await super.init(wallets, fees, addresses)

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

  async set_chain_committer() {
    const call = await this.api.tx.beefyGadget.setCommitmentContract(this.chainMessageCommitter.address)
    const tx = await this.api.tx.sudo.sudo(call).signAndSend(this.alice)
    console.log(`Set chain committer tx submitted with hash: ${tx}`)
    // const res = await this.api.query.beefyGadget.commitmentContract()
    // console.log(`Get chain committer: ${res}`)
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
    const network = "0x50616e676f726f00000000000000000000000000000000000000000000000000"
    const mmr = await this.api.query.mmr.rootHash.at(block_hash)
    const messageRoot = await this.chainMessageCommitter['commitment()']({ blockTag: block_number })
    const next_authority_set = await this.api.query.mmrLeaf.beefyNextAuthorities.at(block_hash)
    return {
        network,
        mmr: mmr.toHex(),
        messageRoot,
        nextValidatorSet: next_authority_set.toJSON()
    }
  }

  async beefy_block() {
    const hash = await this.api.rpc.chain.getFinalizedHead()
    // const hash = await this.api.rpc.beefy.getFinalizedHead()
    // const hash = '0x721cad72e9310e009bb17b48b03a1cf3667b232c7938c5decd3a382c2335f71f';
    console.log(`Finalized head hash ${hash}`)
    const block = await this.api.rpc.chain.getBlock(hash)
    // console.log(`Finalized block #${block.block.header.number} has ${block}`)
    return block
  }

  async beefy_authorities() {
    return this.api.query.beefy.authorities()
  }

}

module.exports.SubClient = SubClient
