const { SparseMerkleTree } = require('@darwinia/contracts-verify/src/utils/sparseMerkleTree')
const { keccakFromHexString } = require("ethereumjs-util");
const { EvmClient } = require('./evmclient')
const {
  genValidatorRoot,
  createAllValidatorProofs,
  createSingleValidatorProof,
  createCompleteValidatorProofs,
  createRandomPositions,
  printBitfield,
  roundUpToPow2
} = require("./helper")

function createMerkleTree(addrs) {
  const len = addrs.length
  const width = roundUpToPow2(len)
  let validatorAddresses = addrs
  for (let i = len; i < width; i++) {
    validatorAddresses.push("0x0000000000000000000000000000000000000000")
  }
  const leavesHashed = validatorAddresses.map(addr => keccakFromHexString(addr));
  return new SparseMerkleTree(leavesHashed);
}

/**
 * The Ethereum client for Bridge interaction
 */
class EthClient extends EvmClient {

  constructor(endpoint) {
    super(endpoint)
  }

  async init(wallets, fees, addresses) {
    await super.init(wallets, fees, addresses)

    const DarwiniaLightClient = await artifacts.readArtifact("DarwiniaLightClient")
    const lightClient = new ethers.Contract(addresses.DarwiniaLightClient, DarwiniaLightClient.abi, this.provider)

    this.lightClient = lightClient.connect(this.signer)
  }

  async block_header(block_number = 'latest') {
    const block = await this.provider.send('eth_getBlockByNumber', ['latest', false]);
    // console.log(`#${block.number}: ${block.stateRoot}`)
    return block
  }

  async relay_real_head(commitment, indices, sigs, raddrs, addrs) {
    const commitmentHash = await this.lightClient.hash(commitment)
    console.log("commitmentHash: ", commitmentHash)

    const z = indices.reduce((o, e, i) => ((o[e] = sigs[i]), o), {});
    const first = indices[0]
    const tree = createMerkleTree(addrs)
    const proof = tree.proofHex([first])

    const initialBitfield = await this.lightClient.createInitialBitfield(indices, addrs.length)

    const newSigTx = await this.lightClient.newSignatureCommitment(
      commitment,
      initialBitfield,
      sigs[0],
      first,
      addrs[first],
      proof,
      {
        value: ethers.utils.parseEther("4")
      }
    )
    console.log("Phase-1: ", newSigTx.hash)
    const lastId = (await this.lightClient.currentId()).sub(1)

    await this.mine(20)

    const completeValidatorProofs = {
      depth: tree.height(),
      signatures: [],
      positions: [],
      decommitments: [],
    }
    const current = await this.lightClient.current()
    const bitfieldInts = await this.lightClient.createRandomBitfield(lastId, current.len);
    const bitfieldString = printBitfield(bitfieldInts);
    const ascendingBitfield = bitfieldString.split('').reverse().join('');
    for (let position = 0; position < ascendingBitfield.length; position++) {
      const bit = ascendingBitfield[position]
      if (bit === '1') {
        completeValidatorProofs.signatures.push(z[position])
        completeValidatorProofs.positions.push(position)
      }
    }
    completeValidatorProofs.decommitments = tree.proofHex(completeValidatorProofs.positions)
    completeValidatorProofs.positions.reverse()
    completeValidatorProofs.signatures.reverse()
    console.log(completeValidatorProofs)

    const completeSigTx = await this.lightClient.completeSignatureCommitment(
      lastId,
      commitment,
      completeValidatorProofs
    )
    console.log("Phase-2: ", completeSigTx.hash)
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
      commitment,
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
