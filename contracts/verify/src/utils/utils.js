const buf2hex = (x) => "0x" + x.toString("hex")
const hex2buf = (x) => Buffer.from(x.slice(2), "hex")

/**
 * Returns the root value of a given Merkle Tree,
 * given the leaves
 * @param {string[]} leaves
 * @returns string
 */
function getMerkleRoot(leaves){
  if (leaves.length > 1) {
    if (leaves.length % 2 !== 0) {
      leaves.push(leaves[leaves.length - 1])
    }
    let j = 0
    let i = 0
    while (i < leaves.length) {
      leaves[j] = ethers.utils.solidityKeccak256(["bytes32", "bytes32"], [leaves[i], leaves[i + 1]])
      j = j + 1
      i = i + 2
    }
    return getMerkleRoot(leaves.slice(0, leaves.length / 2))
  } else {
    return leaves[0]
  }
}

module.exports = { buf2hex, hex2buf, getMerkleRoot }
