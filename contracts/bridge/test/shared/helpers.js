const { keccakFromHexString, keccak } = require("ethereumjs-util");
const assert = require('assert');
const MerkleTree = require("merkletreejs").MerkleTree;
const rlp = require("rlp");

function signatureSubstrateToEthereum(sig) {
  const recoveryId0 = ethers.BigNumber.from(`0x${sig.slice(130)}`);
  const newRecoveryId0 = ethers.utils.hexlify(recoveryId0.add(27));
  const res = sig.slice(0, 130).concat(newRecoveryId0.slice(2));

  return res;
}

function createMerkleTree(leavesHex) {
  const leavesHashed = leavesHex.map(leaf => keccakFromHexString(leaf));
  const merkleTree = new MerkleTree(leavesHashed, keccak, { sort: false });

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

module.exports = {
  createMerkleTree,
  signatureSubstrateToEthereum,
  mine,
  addressBytes,
  encodeLog,
  mergeKeccak256,
  catchRevert: async (promise, message) => await tryCatch(promise, "revert", message),
  catchOutOfGas: async (promise, message) => await tryCatch(promise, "out of gas", message),
  catchInvalidJump: async (promise, message) => await tryCatch(promise, "invalid JUMP", message),
  catchInvalidOpcode: async (promise, message) => await tryCatch(promise, "invalid opcode", message),
  catchStackOverflow: async (promise, message) => await tryCatch(promise, "stack overflow", message),
  catchStackUnderflow: async (promise, message) => await tryCatch(promise, "stack underflow", message),
  catchStaticStateChange: async (promise, message) => await tryCatch(promise, "static state change", message),
};

