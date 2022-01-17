const addresses = require("../bin/addr/local-evm.json")
/**
 * The Ethereum client for Bridge interaction
 */
class EthClient {

  constructor(endpoint) {
    this.provider = new ethers.providers.JsonRpcProvider(endpoint)
  }

  async init() {
    const FeeMarket = await artifacts.readArtifact("FeeMarket");
    this.feeMarket = new ethers.Contract(addresses.FeeMarket, FeeMarket.abi, this.provider)

    const DarwiniaLightClient = await artifacts.readArtifact("DarwiniaLightClient")
    this.lightClient = new ethers.Contract(addresses.DarwiniaLightClient, DarwiniaLightClient.abi, this.provider)

    const OutboundLane = await artifacts.readArtifact("OutboundLane")
    this.outboundLane = new ethers.Contract(addresses.OutboundLane, OutboundLane.abi,  this.provider)

    const InboundLane = await artifacts.readArtifact("InboundLane")
    this.inboundLane = new ethers.Contract(addresses.InboundLane, InboundLane.abi, this.provider)
  }

}

module.exports.EthClient = EthClient
