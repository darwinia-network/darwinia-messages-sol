const _ = require("lodash");
const secp256k1 = require('secp256k1');
const { keccakFromHexString } = require("ethereumjs-util");
const { SparseMerkleTree } = require('@darwinia/contracts-verify/src/utils/sparseMerkleTree')

function roundUpToPow2(len) {
    if (len <= 1) {
      return 1
    } else {
      return 2 * roundUpToPow2(parseInt((len + 1) / 2));
    }
}

function genValidatorRoot(wallets) {
  const walletsByLeaf = wallets.reduce((accum, wallet) => {
    const leaf = '0x' + keccakFromHexString(wallet.address).toString('hex')
    accum[leaf] = wallet
    return accum
  }, {})

  const addrs = wallets.map(wallet => {
    return wallet.address
  })

  const validatorAddressesHashed = addrs.map(address => {
    return '0x' + keccakFromHexString(address).toString('hex')
  })

  let leafs = addrs
  let len = addrs.length
  let width = roundUpToPow2(len)
  for (let i = len; i < width; i++) {
    leafs.push("0x0000000000000000000000000000000000000000")
  }

  const leavesHashed = leafs.map(addr => keccakFromHexString(addr));
  const validatorsMerkleTree = new SparseMerkleTree(leavesHashed);
  const root = validatorsMerkleTree.rootHex()
  return {validatorsMerkleTree, validatorAddressesHashed, walletsByLeaf, root}
}

async function createAllValidatorProofs(commitmentHash, wallets) {
  const {validatorsMerkleTree, validatorAddressesHashed, walletsByLeaf, root} = genValidatorRoot(wallets)
  let commitmentHashBytes = ethers.utils.arrayify(commitmentHash)
  const tree = validatorsMerkleTree
  const leaves = validatorAddressesHashed

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

async function createSingleValidatorProof(position, wallets) {
  const {validatorsMerkleTree} = genValidatorRoot(wallets)
  const indices = [position]
  return validatorsMerkleTree.proofHex(indices)
}

async function createCompleteValidatorProofs(id, beefyLightClient, allValidatorProofs, wallets) {
  const bitfieldInts = await beefyLightClient.createRandomBitfield(id);
  const bitfieldString = printBitfield(bitfieldInts);

  const {validatorsMerkleTree} = genValidatorRoot(wallets)
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

async function createRandomPositions(numberOfPositions, numberOfValidators) {
  const positions = [];
  for (i = 0; i < numberOfValidators; i++) {
    positions.push(i);
  }
  const shuffled = _.shuffle(positions)
  return shuffled.slice(0, numberOfPositions)
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


// genValidatorRoot().then(console.log)

module.exports = {
  genValidatorRoot,
  createAllValidatorProofs,
  createSingleValidatorProof,
  createCompleteValidatorProofs,
  createRandomPositions,
  printBitfield,
  roundUpToPow2
}
