const { keccakFromHexString } = require("ethereumjs-util");
const _ = require("lodash");
const secp256k1 = require('secp256k1');
const { SparseMerkleTree } = require('@darwinia/contracts-verify/src/utils/sparseMerkleTree')

async function mine(n) {
  for (let i = 0; i < n; i++) {
    ethers.provider.send("evm_mine");
  }
}

async function printTxPromiseGas(func, tx) {
  try {
    let r = await tx.wait()
    // console.log(r)
    console.log(`Tx successful - ${func} gas used: ${r.gasUsed}`)
  } catch (e) {
    console.log(`Tx failed - ${func} gas used: ${r.gasUsed}`)
  }
}

function printBitfield(bitfield) {
  const i = bitfield
  const bf = BigInt(i.toString(), 10).toString(2).split('')
  while (bf.length < 256) {
    bf.unshift('0')
  }
  const b = bf.join('')
  return b.replace(/^0*/g, '')
}

function roundUpToPow2(len) {
  if (len <= 1) {
    return 1
  } else {
    return 2 * roundUpToPow2(parseInt((len + 1) / 2));
  }
}

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

  let width = roundUpToPow2(numberOfValidators)
  for (let i = numberOfValidators; i < width; i++) {
    validatorAddresses.push("0x0000000000000000000000000000000000000000")
  }

  const leavesHashed = validatorAddresses.map(addr => keccakFromHexString(addr));
  const validatorsMerkleTree = new SparseMerkleTree(leavesHashed);
  const root = validatorsMerkleTree.rootHex()

  return {
    wallets, walletsByLeaf, validatorAddresses, validatorAddressesHashed, root, validatorsMerkleTree
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
  const tree = beefyFixture.validatorsMerkleTree
  const leaves = beefyFixture.validatorAddressesHashed

  return leaves.map((leaf, position) => {
    const wallet = beefyFixture.walletsByLeaf[leaf]
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

async function createSingleValidatorProof(position, beefyFixture) {
  const indices = [position]
  return beefyFixture.validatorsMerkleTree.proofHex(indices)
}

async function createCompleteValidatorProofs(id, beefyLightClient, allValidatorProofs, beefyFixture) {
  const bitfieldInts = await beefyLightClient.createRandomBitfield(id);
  const bitfieldString = printBitfield(bitfieldInts);

  const completeValidatorProofs = {
    depth: beefyFixture.validatorsMerkleTree.height(),
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

  completeValidatorProofs.decommitments = beefyFixture.validatorsMerkleTree.proofHex(completeValidatorProofs.positions)
  completeValidatorProofs.positions.reverse()
  completeValidatorProofs.signatures.reverse()

  return completeValidatorProofs
}

module.exports = {
  mine,
  printTxPromiseGas,
  createBeefyValidatorFixture,
  createRandomPositions,
  createAllValidatorProofs,
  createAllGuardProofs,
  createCompleteValidatorProofs,
  createSingleValidatorProof,
}
