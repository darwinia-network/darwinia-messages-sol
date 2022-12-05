const { defaultAbiCoder } = require("@ethersproject/abi")
const keccak256 = ethers.utils.keccak256

function messageHash(msg) {
  console.log(msg)
  return keccak256(defaultAbiCoder.encode(
    [
      "bytes32",
      "uint256",
      "bytes32"
    ],
    [
      "0xfc686c8227203ee2031e2c031380f840b8cea19f967c05fc398fdeb004e7bf8b",
      msg.encoded_key,
      hash(msg.payload)
    ]
  ))
}

function hash(payload) {
  return keccak256(defaultAbiCoder.encode(
    [
      "bytes32",
      "address",
      "address",
      "bytes32"
    ],
    [
      "0x582ffe1da2ae6da425fa2c8a2c423012be36b65787f7994d78362f66e4f84101",
      payload.source,
      payload.target,
      keccak256(payload.encoded)
    ]
  ))
}

module.exports = {
  messageHash,
}
