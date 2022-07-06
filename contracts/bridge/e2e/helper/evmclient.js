/**
 * The EVM client for Bridge interaction
 */
class EvmClient {

  constructor(endpoint) {
    this.provider = new ethers.providers.JsonRpcProvider(endpoint)
  }

  async init(wallets, fees, addresses, ns) {
    this.wallets = wallets
    if (addresses[ns].FeeMarket) {
      const FeeMarket = await artifacts.readArtifact("FeeMarket");
      this.feeMarket = new ethers.Contract(addresses[ns].FeeMarket, FeeMarket.abi, this.provider)
    } else {
      const SimpleFeeMarket = await artifacts.readArtifact("SimpleFeeMarket");
      this.feeMarket = new ethers.Contract(addresses[ns].SimpleFeeMarket, SimpleFeeMarket.abi, this.provider)
    }

    const OutboundLane = await artifacts.readArtifact("OutboundLane")
    const outbound = new ethers.Contract(addresses[ns].OutboundLane, OutboundLane.abi,  this.provider)

    const InboundLane = await artifacts.readArtifact("InboundLane")
    const inbound = new ethers.Contract(addresses[ns].InboundLane, InboundLane.abi, this.provider)

    this.signer = wallets[0].connect(this.provider)
    this.outbound = outbound.connect(this.signer)
    this.inbound = inbound.connect(this.signer)
    this.wallets = wallets
    this.fees = fees
  }

  get_signer(index) {
    return this.wallets[index].connect(this.provider)
  }

  async enroll_relayer() {
    let prev = "0x0000000000000000000000000000000000000001"
    for(let i=0; i<this.wallets.length; i++) {
      let fee = this.fees[i]
      let signer = this.wallets[i]
      const tx = await this.feeMarket.connect(signer.connect(this.provider)).enroll(prev, fee, {
        value: ethers.utils.parseEther("100"),
        gasLimit: 300000
      })
      prev = signer.address
    }
  }

  async deposit() {
    for(let i=0; i<this.wallets.length; i++) {
      let signer = this.wallets[i]
      await this.feeMarket.connect(signer.connect(this.provider)).deposit({
        value: ethers.utils.parseEther("100"),
        gasLimit: 300000
      })
    }
  }

  async get_block(number) {
    const b = await this.provider.send("eth_getBlockByNumber", [ number, false ])
    return {
        parent_hash: b.parentHash,
        uncle_hash: b.sha3Uncles,
        coinbase: b.miner,
        state_root: b.stateRoot,
        transactions_root: b.transactionsRoot,
        receipts_root: b.receiptsRoot,
        log_bloom: b.logsBloom,
        difficulty: b.difficulty,
        number: b.number,
        gas_limit: b.gasLimit,
        gas_used: b.gasUsed,
        timestamp: b.timestamp,
        extra_data: b.extraData,
        mix_digest: b.mixHash,
        nonce: b.nonce
    }
  }
}

module.exports.EvmClient = EvmClient
