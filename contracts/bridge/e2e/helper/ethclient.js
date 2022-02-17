const addresses = require("../../bin/addr/local-evm.json")
const { EvmClient } = require('./evmclient')
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
class EthClient extends EvmClient {

  constructor(endpoint) {
    super(endpoint)
  }

  async init(wallets, fees) {
    await super.init(addresses, wallets, fees)

    const DarwiniaLightClient = await artifacts.readArtifact("DarwiniaLightClient")
    const lightClient = new ethers.Contract(addresses.DarwiniaLightClient, DarwiniaLightClient.abi, this.provider)

    this.lightClient = lightClient.connect(this.signer)
  }

  async block_header(block_number = 'latest') {
    const block = await this.provider.send('eth_getBlockByNumber', ['latest', false]);
    // console.log(`#${block.number}: ${block.stateRoot}`)
    return block
  }

  async relay_header(message_root, block_number) {
    const commitment = {
      "payload": {
        "network": "0x50616e676f6c696e000000000000000000000000000000000000000000000000",
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
    const commitmentHash = await this.lightClient.hash(commitment)
    const initialBitfieldPositions = await createRandomPositions(3, 3)

    const firstPosition = initialBitfieldPositions[0]
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
    // console.log("Phase-1: ", newSigTx.hash)
    // console.log("lastID: ", lastId.toString())

    await this.mine(20)

    const completeValidatorProofs = await createCompleteValidatorProofs(lastId, this.lightClient, allValidatorProofs, this.wallets)

    const completeSigTx = await this.lightClient.completeSignatureCommitment(
      lastId,
      commitment,
      completeValidatorProofs
    )
    // console.log("Phase-2: ", completeSigTx.hash)
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
