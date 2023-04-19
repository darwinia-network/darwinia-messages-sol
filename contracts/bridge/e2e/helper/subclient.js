const { ApiPromise, WsProvider, Keyring } = require('@polkadot/api');
const { EvmClient } = require('./evmclient')
const { encodeNextAuthoritySet } = require('./encode')
const { signHash } = require('./eip712')
const ethUtil = require('ethereumjs-util');

/**
 * The Substrate client for Bridge interaction
 */
class SubClient {

  constructor(http_endpoint, ws_endpoint) {
    this.http_endpoint = http_endpoint
    this.sub_provider = new WsProvider(ws_endpoint)
    this.provider = new ethers.providers.JsonRpcProvider(http_endpoint)
  }

  async init(wallets, fees, addresses, ns_eth, ns_bsc) {
    this.eth = new EvmClient(this.http_endpoint)
    this.bsc = new EvmClient(this.http_endpoint)
    this.eth.init(wallets, fees, addresses, ns_eth)
    this.bsc.init(wallets, fees, addresses, ns_bsc)

    this.api = await ApiPromise.create({
      provider: this.sub_provider
    })
    this.keyring = new Keyring({ type: 'sr25519' });
    this.alice = this.keyring.addFromUri('//Alice', { name: 'Alice' });
    this.bob = this.keyring.addFromUri('//Bob', { name: 'Bob' });

    const ChainMessageCommitter = await artifacts.readArtifact("ChainMessageCommitter");
    this.chainMessageCommitter = new ethers.Contract(addresses.ChainMessageCommitter, ChainMessageCommitter.abi, this.provider)

    const LaneMessageCommitter = await artifacts.readArtifact("LaneMessageCommitter");
    this.ethLaneMessageCommitter = new ethers.Contract(addresses[ns_eth].LaneMessageCommitter, LaneMessageCommitter.abi, this.provider)
    this.eth.LaneMessageCommitter = this.ethLaneMessageCommitter

    // this.bscLaneMessageCommitter = new ethers.Contract(addresses[ns_bsc].LaneMessageCommitter, LaneMessageCommitter.abi, this.provider)
    // this.bsc.LaneMessageCommitter = this.bscLaneMessageCommitter

    const BeaconLightClient = await artifacts.readArtifact("BeaconLightClient")
    const beaconLightClient = new ethers.Contract(addresses[ns_eth].BeaconLightClient, BeaconLightClient.abi, this.provider)

    // const BSCLightClient = await artifacts.readArtifact("BSCLightClient")
    // const bscLightClient = new ethers.Contract(addresses[ns_bsc].BSCLightClientProxy, BSCLightClient.abi, this.provider)
    this.signer = wallets[0].connect(this.provider)
    this.beaconLightClient = beaconLightClient.connect(this.signer)
    // this.bscLightClient = bscLightClient.connect(this.signer)
    this.eth.lightclient = this.beaconLightClient
    // this.bsc.lightclient = this.bscLightClient

  }

  chill() {
    return this.api.tx.staking.chill().signAndSend(this.bob)
  }

  async set_chain_committer() {
    console.log(this.api.tx.beefyGadget)
    const call = await this.api.tx.beefyGadget.setCommitmentContract(this.chainMessageCommitter.address)
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
    const network = "0x50616e676f6c696e000000000000000000000000000000000000000000000000"
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
    // console.log(`Finalized head hash ${hash}`)
    const block = await this.api.rpc.chain.getBlock(hash)
    console.log(`Finalized block #${block.block.header.number} has ${hash}`)
    return block
  }

  async beefy_authorities(hash) {
    return this.api.query.beefy.authorities.at(hash)
  }

  async ecdsa_authority_nonce(block_number) {
    return await this.api.query.ecdsaAuthority.nonce.at(block_number)
  }

  async sign_message_commitment(message) {
    // bridger could get the hash from `edcsa-authority` pallet's events.
    const hash = signHash(message)
    const PRIVATE_KEY = process.env.PRIVATE_KEY
    const privateKey = Buffer.from(PRIVATE_KEY.substr(2), 'hex')
    const sig = ethUtil.ecsign(hash, privateKey);

    const pubkey = ethUtil.ecrecover(hash, sig.v, sig.r, sig.s)
    return [ethUtil.toRpcSig(sig.v, sig.r, sig.s)]
  }
}

module.exports.SubClient = SubClient
