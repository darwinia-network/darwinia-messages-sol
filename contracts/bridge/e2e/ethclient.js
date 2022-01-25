const addresses = require("../bin/addr/local-evm.json")
const {
  genValidatorRoot,
  createAllValidatorProofs,
  createSingleValidatorProof,
  createCompleteValidatorProofs,
  createRandomPositions,
  printBitfield
} = require("./helper")

/**
 * The Ethereum client for Bridge interaction
 */
class EthClient {

  constructor(endpoint) {
    this.provider = new ethers.providers.JsonRpcProvider(endpoint)
  }

  async init(wallets, fees) {
    this.wallets = wallets
    const FeeMarket = await artifacts.readArtifact("FeeMarket");
    this.feeMarket = new ethers.Contract(addresses.FeeMarket, FeeMarket.abi, this.provider)

    const DarwiniaLightClient = await artifacts.readArtifact("DarwiniaLightClient")
    const lightClient = new ethers.Contract(addresses.DarwiniaLightClient, DarwiniaLightClient.abi, this.provider)

    const OutboundLane = await artifacts.readArtifact("OutboundLane")
    const outbound = new ethers.Contract(addresses.OutboundLane, OutboundLane.abi,  this.provider)

    const InboundLane = await artifacts.readArtifact("InboundLane")
    const inbound = new ethers.Contract(addresses.InboundLane, InboundLane.abi, this.provider)

    let prev = "0x0000000000000000000000000000000000000001"
    for(let i=0; i<wallets.length; i++) {
      let fee = fees[i]
      let signer = wallets[i]
      await this.feeMarket.connect(signer.connect(this.provider)).enroll(prev, fee, {
        value: ethers.utils.parseEther("100")
      })
      prev = signer.address
    }

    let signer = wallets[0].connect(this.provider)
    this.lightClient = lightClient.connect(signer)
    this.outbound = outbound.connect(signer)
    this.inbound = inbound.connect(signer)
  }

  async block_header(block_number = 'latest') {
    const block = await this.provider.send('eth_getBlockByNumber', ['latest', false]);
    console.log(`#${block.number}: ${block.stateRoot}`)
    return block
  }

  async relay_header(message_root, block_number) {
    const commitment = {
      "payload": {
        "network": "0x6c6f63616c2d65766d0000000000000000000000000000000000000000000000",
        "mmr": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "messageRoot": message_root,
        "nextValidatorSet": {
          "id": 0,
          "len": 0,
          "root": "0x0000000000000000000000000000000000000000000000000000000000000000"
        }
      },
      "blockNumber": block_number,
      "validatorSetId": 0
    }
    console.log(commitment)
    const commitmentHash = await this.lightClient.hash(commitment)
    console.log(commitmentHash)
    const initialBitfieldPositions = await createRandomPositions(3, 3)
    console.log(initialBitfieldPositions)

    const firstPosition = initialBitfieldPositions[0]
    console.log(firstPosition)
    const firstProof = await createSingleValidatorProof(firstPosition, this.wallets)
    const allValidatorProofs = await createAllValidatorProofs(commitmentHash, this.wallets);
    const initialBitfield = await this.lightClient.createInitialBitfield(
      initialBitfieldPositions, 3
    )
    const newSigTx = await this.lightClient.newSignatureCommitment(
      commitmentHash,
      initialBitfield,
      allValidatorProofs[firstPosition].signature,
      firstPosition,
      allValidatorProofs[firstPosition].address,
      firstProof,
      {
        value: ethers.utils.parseEther("4")
      }
    )
    const lastId = (await this.lightClient.currentId()).sub(1)
    console.log("Phase-1: ", newSigTx.hash)
    console.log("lastID: ", lastId.toString())

    await this.mine(20)

    const completeValidatorProofs = await createCompleteValidatorProofs(lastId, this.lightClient, allValidatorProofs, this.wallets)

    const completeSigTx = await this.lightClient.completeSignatureCommitment(
      lastId,
      commitment,
      completeValidatorProofs
    )
    console.log("Phase-2: ", completeSigTx.hash)
  }

  async mine(n) {
    for (let i = 0; i < n; i++) {
      await this.wallets[0].connect(this.provider).sendTransaction(
        {
          to: this.wallets[1].address
        }
      )
      // this.provider.send("evm_mine");
    }
  }

}

module.exports.EthClient = EthClient
