const addresses = require("../bin/addr/local-dvm.json")

/**
 * The Substrate client for Bridge interaction
 */
class SubClient {

  constructor(endpoint) {
    this.provider = new ethers.providers.JsonRpcProvider(endpoint)
  }

  async init() {
    const ChainMessageCommitter = await artifacts.readArtifact("ChainMessageCommitter");
    this.chainMessageCommitter = new ethers.Contract(addresses.ChainMessageCommitter, ChainMessageCommitter.abi, this.provider)

    const LaneMessageCommitter = await artifacts.readArtifact("LaneMessageCommitter");
    this.laneMessageCommitter = new ethers.Contract(addresses.LaneMessageCommitter, LaneMessageCommitter.abi, this.provider)

    const FeeMarket = await artifacts.readArtifact("FeeMarket");
    this.feeMarket = new ethers.Contract(addresses.FeeMarket, FeeMarket.abi, this.provider)

    const BSCLightClient = await artifacts.readArtifact("BSCLightClient")
    this.lightClient = new ethers.Contract(addresses.BSCLightClient, BSCLightClient.abi, this.provider)

    const OutboundLane = await artifacts.readArtifact("OutboundLane")
    this.outbound = new ethers.Contract(addresses.OutboundLane, OutboundLane.abi, this.provider)

    const InboundLane = await artifacts.readArtifact("InboundLane")
    this.inbound = new ethers.Contract(addresses.InboundLane, InboundLane.abi, this.provider)

    let overrides = {
        value: ethers.utils.parseEther("100")
    }
    let prev = "0x0000000000000000000000000000000000000001"
    privs.forEach(async (priv, i) => {
      let fee = fees[i]
      let signer = new ethers.Wallet(priv, this.provider)
      await this.feeMarket.connect(signer).enroll(prev, fee, overrides)
      prev = signer.address
    })
  }

}

module.exports.SubClient = SubClient;