const addresses = require("../bin/addr/local-evm.json")

/**
 * The Ethereum client for Bridge interaction
 */
class EthClient {

  constructor(endpoint) {
    this.provider = new ethers.providers.JsonRpcProvider(endpoint)
  }

  async init(privs, fees) {
    const FeeMarket = await artifacts.readArtifact("FeeMarket");
    this.feeMarket = new ethers.Contract(addresses.FeeMarket, FeeMarket.abi, this.provider)

    const DarwiniaLightClient = await artifacts.readArtifact("DarwiniaLightClient")
    this.lightClient = new ethers.Contract(addresses.DarwiniaLightClient, DarwiniaLightClient.abi, this.provider)

    const OutboundLane = await artifacts.readArtifact("OutboundLane")
    this.outbound = new ethers.Contract(addresses.OutboundLane, OutboundLane.abi,  this.provider)

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

module.exports.EthClient = EthClient
