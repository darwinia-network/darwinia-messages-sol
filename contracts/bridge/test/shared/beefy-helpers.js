const { ethers } = require("ethers");
const _ = require("lodash");
const secp256k1 = require('secp256k1');

const {
  createMerkleTree, mine, printBitfield
} = require("./helpers");

const { keccakFromHexString } = require("ethereumjs-util");

async function createBeefyValidatorFixture(numberOfValidators) {

  let wallets = [];
  for (let i = 0; i < numberOfValidators; i++) {
    const wallet = ethers.Wallet.createRandom();
    wallets.push(wallet);
  }

  wallets = wallets.sort((a, b) => a.address.toLowerCase().localeCompare(b.address.toLowerCase()))

  const validatorAddresses = wallets.map(wallet => {
    return wallet.address
  })

  const walletsByLeaf = wallets.reduce((accum, wallet) => {
    const leaf = '0x' + keccakFromHexString(wallet.address).toString('hex')
    accum[leaf] = wallet
    return accum
  }, {})

  const validatorAddressesHashed = validatorAddresses.map(address => {
    return '0x' + keccakFromHexString(address).toString('hex')
  })

  const validatorsMerkleTree = createMerkleTree(validatorAddresses);
  const validatorAddressProofs = validatorAddresses.map((address, index) => {
    return validatorsMerkleTree.getHexProof(address, index)
  })
  const root = validatorsMerkleTree.getHexRoot()

  return {
    wallets, walletsByLeaf, validatorAddresses, validatorAddressesHashed, root, validatorAddressProofs, validatorsMerkleTree
  }
}

async function createRandomPositions(numberOfPositions, numberOfValidators) {

  const positions = [];
  for (i = 0; i < numberOfValidators; i++) {
    positions.push(i);
  }

  const shuffled = _.shuffle(positions)

  return shuffled.slice(0, numberOfPositions)
}

async function createAllValidatorProofs(commitmentHash, beefyFixture) {
  let commitmentHashBytes = ethers.utils.arrayify(commitmentHash)
  const tree = beefyFixture.validatorsMerkleTree;
  const leaves = tree.getHexLeaves()

  return leaves.map((leaf, position) => {
    const wallet = beefyFixture.walletsByLeaf[leaf]
    const address = wallet.address
    const proof = tree.getHexProof(leaf, position)
    const privateKey = ethers.utils.arrayify(wallet.privateKey)
    const signatureECDSA = secp256k1.ecdsaSign(commitmentHashBytes, privateKey)
    const ethRecID = signatureECDSA.recid + 27
    const signature = Uint8Array.from(
      signatureECDSA.signature.join().split(',').concat(ethRecID)
    )
    return { signature: ethers.utils.hexlify(signature), position, address, proof };
  });
}

async function createAllGuardProofs(commitmentHash, beefyFixture, domainSeperator, guards) {
  const hexPrefix = /^(0x)/i
  const data = '0x' +  "1901" + domainSeperator.replace(hexPrefix, '') + commitmentHash.replace(hexPrefix, "")
  const dataHash = '0x' + keccakFromHexString(data, 256).toString('hex')

  let dataHashBytes = ethers.utils.arrayify(dataHash)

  return guards.map((leaf, position) => {
    const wallet = beefyFixture.wallets[position]
    const address = wallet.address
    const privateKey = ethers.utils.arrayify(wallet.privateKey)
    const signatureECDSA = secp256k1.ecdsaSign(dataHashBytes, privateKey)
    const ethRecID = signatureECDSA.recid + 27
    const signature = Uint8Array.from(
      signatureECDSA.signature.join().split(',').concat(ethRecID)
    )
    return ethers.utils.hexlify(signature);
  });
}

async function createCompleteValidatorProofs(id, beefyLightClient, allValidatorProofs) {
  const bitfieldInts = await beefyLightClient.createRandomBitfield(id);
  const bitfieldString = printBitfield(bitfieldInts);

  const completeValidatorProofs = {
    signatures: [],
    positions: [],
    signers: [],
    signerProofs: [],
  }

  const ascendingBitfield = bitfieldString.split('').reverse().join('');
  for (let position = 0; position < ascendingBitfield.length; position++) {
    const bit = ascendingBitfield[position]
    if (bit === '1') {
      completeValidatorProofs.signatures.push(allValidatorProofs[position].signature)
      completeValidatorProofs.positions.push(allValidatorProofs[position].position)
      completeValidatorProofs.signers.push(allValidatorProofs[position].address)
      completeValidatorProofs.signerProofs.push(allValidatorProofs[position].proof)
    }
  }

  return completeValidatorProofs
}

module.exports = {
  createBeefyValidatorFixture,
  createRandomPositions,
  createAllValidatorProofs,
  createAllGuardProofs,
  createCompleteValidatorProofs,
}
