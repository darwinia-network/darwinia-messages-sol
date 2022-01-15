const { keccakFromHexString, keccak } = require("ethereumjs-util");
const assert = require('assert');
const MerkleTree = require("merkletreejs").MerkleTree;
const rlp = require("rlp");

function buildCommitment(msgs) {
  return ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(["(address,address,address,uint256,bytes)[]"], [ msgs ]))
}

function createMerkleTree(leavesHex) {
  const leavesHashed = leavesHex.map(leaf => keccakFromHexString(leaf));
  const merkleTree = new MerkleTree(leavesHashed, keccak, { sort: false, duplicateOdd: false });

  return merkleTree;
}

async function mine(n) {
  for (let i = 0; i < n; i++) {
    ethers.provider.send("evm_mine");
  }
}

const addressBytes = (address) => Buffer.from(address.replace(/^0x/, ""), "hex");

const encodeLog = (log) => {
  return rlp.encode([log.address, log.topics, log.data]).toString("hex")
}

const hexPrefix = /^(0x)/i

const mergeKeccak256 = (left, right) =>
  '0x' + keccakFromHexString('0x' + left.replace(hexPrefix, "") + right.replace(hexPrefix, ''), 256).toString('hex')

const PREFIX = "VM Exception while processing transaction: ";

async function tryCatch(promise, type, message) {
    try {
        await promise;
        throw null;
    }
    catch (error) {
      assert(error, "Expected an error but did not get one");
      if (message) {
        assert(error.message === (PREFIX + type + ' ' + message), "Expected error '" + PREFIX + type + ' ' + message +
          "' but got '" + error.message + "' instead");
      } else {
        assert(error.message.startsWith(PREFIX + type), "Expected an error starting with '" + PREFIX + type +
          "' but got '" + error.message + "' instead");
      }
    }
};

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
  return bitfield.map(i => {
    const bf = BigInt(i.toString(), 10).toString(2).split('')
    while (bf.length < 256) {
      bf.unshift('0')
    }
    return bf.join('')
  }).reverse().join('').replace(/^0*/g, '')
}

module.exports = {
  buildCommitment,
  createMerkleTree,
  mine,
  addressBytes,
  encodeLog,
  mergeKeccak256,
  printTxPromiseGas,
  printBitfield,
  catchRevert: async (promise, message) => await tryCatch(promise, "revert", message),
  catchOutOfGas: async (promise, message) => await tryCatch(promise, "out of gas", message),
  catchInvalidJump: async (promise, message) => await tryCatch(promise, "invalid JUMP", message),
  catchInvalidOpcode: async (promise, message) => await tryCatch(promise, "invalid opcode", message),
  catchStackOverflow: async (promise, message) => await tryCatch(promise, "stack overflow", message),
  catchStackUnderflow: async (promise, message) => await tryCatch(promise, "stack underflow", message),
  catchStaticStateChange: async (promise, message) => await tryCatch(promise, "static state change", message),
};

