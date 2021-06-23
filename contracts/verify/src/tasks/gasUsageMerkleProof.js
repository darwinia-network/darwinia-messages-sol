const { subtask, task } = require("hardhat/config")
const { MerkleTree } = require("merkletreejs")
const { buf2hex, hex2buf, getMerkleRoot } = require("../utils/utils")
const { keccakFromString, keccak } = require("ethereumjs-util")
const generateSampleData = require("../utils/sampleData")

const taskSetup = async (hre) => {
  const dataLengths = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048]
  const dataObjs = dataLengths.map(d => {
    return { length: d, data: [...generateSampleData(d)].map(b => keccakFromString(b)).map(buf2hex) }
  })

  const Verification = await hre.ethers.getContractFactory("MerkleProofTest")
  const verificationContract = await Verification.deploy()

  return {
    dataObjs,
    verificationContract,
  }
}

task("gasUsage")
  .setDescription("Prints out the gas usage for each of the merkle proof verification functions")
  .setAction(async (_, { run }) => {
    await run("verifyMessageArray")
    await run("verifyMessageArrayUnpacked")
    await run("verifyMerkleLeaf")
    await run("verifyMerkleAll")
  })

subtask("verifyMessageArray").setAction(async (_, hre) => {
  console.log("----------------verifyMessageArray-----------------")
  const { dataObjs, verificationContract } = await taskSetup(hre)

  for (let i = 0; i < dataObjs.length; i++) {
    const element = dataObjs[i]
    const commitment = element.data.reduce((prev, curr) =>
      hre.ethers.utils.solidityKeccak256(["bytes32", "bytes32"], [prev, curr])
    )
    console.log(
      `  ↪ Data length ${element.length}: `,
      (await verificationContract.estimateGas.verifyMessageArray(element.data, commitment)).toString()
    )
  }
})

subtask("verifyMessageArrayUnpacked").setAction(async (_, hre) => {
  console.log("-----------verifyMessageArrayUnpacked--------------")
  const { dataObjs, verificationContract } = await taskSetup(hre)

  for (let i = 0; i < dataObjs.length; i++) {
    const element = dataObjs[i]
    const commitment = hre.ethers.utils.keccak256(hre.ethers.utils.defaultAbiCoder.encode(["bytes32[]"], [ element.data ]))
    console.log(
      `  ↪ Data length ${element.length}: `,
      (await verificationContract.estimateGas.verifyMessagesArrayUnpacked(element.data, commitment)).toString()
    )
  }
})

subtask("verifyMerkleLeaf").setAction(async (_, hre) => {
  console.log("-----------------verifyMerkleLeaf-------------------")
  const { dataObjs, verificationContract } = await taskSetup(hre)

  for (let i = 0; i < dataObjs.length; i++) {
    const element = dataObjs[i]
    const tree = new MerkleTree(element.data, keccak, { sort: true })
    const hexRoot = tree.getHexRoot()
    const hexLeaf = element.data[0]
    const hexProof = tree.getHexProof(hex2buf(hexLeaf))
    console.log(
      `  ↪ Data length ${element.length}: `,
      (await verificationContract.estimateGas.verifyMerkleLeaf(hexRoot, hexLeaf, hexProof)).toString()
    )
  }
})

subtask("verifyMerkleAll").setAction(async (_, hre) => {
  console.log("----------------verifyMerkleAll---------------------")
  const { dataObjs, verificationContract } = await taskSetup(hre)

  for (let i = 0; i < dataObjs.length; i++) {
    const element = dataObjs[i]
    const sortedLeaves = element.data
      .map(hex2buf)
      // eslint-disable-next-line @typescript-eslint/unbound-method
      .sort(Buffer.compare)
      .map(buf2hex)
    const merkleRoot = getMerkleRoot(sortedLeaves)

    console.log(
      `  ↪ Data length ${element.length}: `,
      (await verificationContract.estimateGas.verifyMerkleAll(sortedLeaves, merkleRoot)).toString()
    )
  }
})
