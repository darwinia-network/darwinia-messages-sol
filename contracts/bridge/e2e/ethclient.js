const addresses = require("../bin/addr/local-evm.json")
const { genValidatorRoot } = require("genValidatorRoot")

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

  async relay_header(message_root, block_number) {
    const commitment = {
      "payload": {
        "network": "0x6c6f63616c2d65766d0000000000000000000000000000000000000000000000",
        "mmr": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "messageRoot": message_root
      },
      "blockNumber": block_number,
      "validatorSetId": 0
    }
    const commitmentHash = await this.lightClient.hash(commitment)
    const initialBitfieldPositions = await createRandomPositions(3, 3)
    const firstPosition = initialBitfieldPositions[0]
    const firstProof = await createSingleValidatorProof(firstPosition, fixture)
    const allValidatorProofs = await createAllValidatorProofs(commitmentHash);
    let overrides = {
        value: ethers.utils.parseEther("4")
    }
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
      overrides
    )
    const lastId = await beefyLightClient.currentId()).sub(BigNumber.from(1)
    console.log("Phase-1: ", newSigTx)
    console.log("lastID: ", lastId)
    const completeValidatorProofs = await createCompleteValidatorProofs(lastId, this.lightClient, allValidatorProofs);

    const completeSigTx = await this.lightClient.completeSignatureCommitment(
      lastId,
      commitment,
      completeValidatorProofs
    )
    console.log("Phase-2: ", completeSigTx)
  }

}

async function createAllValidatorProofs(commitmentHash) {
  const {validatorsMerkleTree, leavesHashed, walletsByLeaf, root} = genValidatorRoot()
  let commitmentHashBytes = ethers.utils.arrayify(commitmentHash)
  const tree = validatorsMerkleTree
  const leaves = leavesHashed

  return leaves.map((leaf, position) => {
    const wallet = walletsByLeaf[leaf]
    const address = wallet.address
    const privateKey = ethers.utils.arrayify(wallet.privateKey)
    const signatureECDSA = secp256k1.ecdsaSign(commitmentHashBytes, privateKey)
    const ethRecID = signatureECDSA.recid + 27
    const signature = Uint8Array.from(
      signatureECDSA.signature.join().split(',').concat(ethRecID)
    )
    return { signature: ethers.utils.hexlify(signature), position, address };
  });
}

async function createRandomPositions(numberOfPositions, numberOfValidators) {

  const positions = [];
  for (i = 0; i < numberOfValidators; i++) {
    positions.push(i);
  }

  const shuffled = _.shuffle(positions)

  return shuffled.slice(0, numberOfPositions)
}

async function createSingleValidatorProof(position) {
  const {validatorsMerkleTree} = genValidatorRoot()
  const indices = [position]
  return validatorsMerkleTree.proofHex(indices)
}

function printBitfield(bitfield) {
  return bitfield.map(i => {
    const bf = BigInt(i.toString(), 10).toString(2).split('')
    while (bf.length < 256) {
      bf.unshift('0')
    }
    return bf.join('')
  }).reverse().join('').replace(/^0*/g, '')
}

async function createCompleteValidatorProofs(id, beefyLightClient, allValidatorProofs) {
  const bitfieldInts = await beefyLightClient.createRandomBitfield(id);
  const bitfieldString = printBitfield(bitfieldInts);

  const {validatorsMerkleTree} = genValidatorRoot()
  const completeValidatorProofs = {
    depth: validatorsMerkleTree.height(),
    signatures: [],
    positions: [],
    decommitments: [],
  }

  const ascendingBitfield = bitfieldString.split('').reverse().join('');
  for (let position = 0; position < ascendingBitfield.length; position++) {
    const bit = ascendingBitfield[position]
    if (bit === '1') {
      completeValidatorProofs.signatures.push(allValidatorProofs[position].signature)
      completeValidatorProofs.positions.push(allValidatorProofs[position].position)
    }
  }

  completeValidatorProofs.decommitments = validatorsMerkleTree.proofHex(completeValidatorProofs.positions)
  completeValidatorProofs.positions.reverse()
  completeValidatorProofs.signatures.reverse()

  return completeValidatorProofs
}

module.exports.EthClient = EthClient
