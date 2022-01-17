const addresses = require("../bin/addr/local-dvm.json")

/**
 * The Substrate client for Bridge interaction
 */
class SubClient {

  constructor(endpoint) {
    this.provider = new ethers.providers.JsonRpcProvider(endpoint)
  }

  async init() {
    const FeeMarket = await artifacts.readArtifact("FeeMarket");
    this.feeMarket = new ethers.Contract(addresses.FeeMarket, FeeMarket.abi, this.provider)

    const BSCLightClient = await artifacts.readArtifact("BSCLightClient")
    this.lightClient = new ethers.Contract(addresses.BSCLightClient, BSCLightClient.abi, this.provider)

    const OutboundLane = await artifacts.readArtifact("OutboundLane")
    this.outboundLane = new ethers.Contract(addresses.OutboundLane, OutboundLane.abi, this.provider)

    const InboundLane = await artifacts.readArtifact("InboundLane")
    this.inboundLane = new ethers.Contract(addresses.InboundLane, InboundLane.abi, this.provider)
  }

}

module.exports.SubClient = SubClient;
