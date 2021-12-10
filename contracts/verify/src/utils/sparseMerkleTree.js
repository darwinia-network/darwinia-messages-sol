const { keccak256, bufferToHex } = require('ethereumjs-util');
const assert = require('assert');

class SparseMerkleTree {
  constructor(leafs) {
    this.leafs = leafs
    let num_leafs = this.leafs.length
    this.num_leafs = num_leafs
    let num_nodes = 2 * num_leafs
    this.num_nodes = num_nodes
    let depth = parseInt(Math.log2(num_leafs))
    this.depth = depth
    assert.equal(num_leafs, 2**depth)
    // Create tree
    let tree = Array(num_nodes)
    for (let i=0; i < num_leafs; i++) {
      tree[2**depth + i] = this.hash_leaf(leafs[i])
    }
    for (let i=2**depth - 1; i > 0; i--) {
      tree[i] = this.hash_node(tree[2*i], tree[2*i+1])
    }
    this.tree = tree
  }

  hash_leaf(leaf) {
    return Buffer.from(leaf)
  }

  hash_node(left, right) {
    return keccak256(this.concat(left, right));
  }

  concat(...args) {
    return Buffer.concat([...args]);
  }

  root() {
    return this.tree[1]
  }

  rootHex() {
    return bufferToHex(this.root())
  }

  height() {
    return this.depth
  }

  proof(indices) {
    let depth = this.depth
    let num_leafs = this.num_leafs
    let num_nodes = this.num_nodes
    let tree = this.tree
    let known = Array(num_nodes).fill(false)
    let decommitment = []
    for (let i of indices) {
      known[2**depth + i] = true
    }
    for (let i=2**depth - 1; i > 0; i--) {
      let left = known[2*i]
      let right = known[2*i+1]
      if (left && !right) {
        decommitment.push(tree[2*i + 1])
      }
      if (!left && right) {
        decommitment.push(tree[2*i])
      }
      known[i] = left || right
    }
    return decommitment
  }

  proofHex(indices) {
    return this.bufArrToHex(this.proof(indices))
  }

  verify(values, decommitment, debug_print=false) {
    let depth = this.depth
    let queue = []
    for (let index of Object.keys(values).sort((a, b) => b - a)) {
      let tree_index = 2**depth + parseInt(index)
      let hash = this.hash_leaf(values[index])
      queue.push([tree_index, hash])
    }
    while (true) {
      assert.ok(queue.length >= 1)
      let [ index, hash ] = queue[0]
      queue.shift()
      if (debug_print) {
        console.log(index, bufferToHex(hash))
      }

      if (index == 1) {
        return Buffer.compare(hash, this.root()) == 0
      } else if (index % 2 == 0) {
        queue.push([ parseInt(index/2), this.hash_node(hash, decommitment[0]) ])
        decommitment.shift()
      } else if (queue.length > 0 && queue[0][0] == index - 1) {
        let [ , sibbling_hash ] = queue[0]
        queue.shift()
        queue.push([ parseInt(index/2), this.hash_node(sibbling_hash, hash) ])
      } else {
        queue.push([ parseInt(index/2), this.hash_node(decommitment[0], hash) ])
        decommitment.shift()
      }
    }
  }

  print() {
    console.log(this.bufArrToHex(this.tree))
  }

  bufArrToHex(arr) {
    if (arr.some(el => !Buffer.isBuffer(el))) {
      throw new Error("Array is not an array of buffers");
    }
    return arr.map(el => '0x' + el.toString('hex'));
  }

}

exports.SparseMerkleTree = SparseMerkleTree;
