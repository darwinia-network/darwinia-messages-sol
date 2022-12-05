const { toHexString } = require('@chainsafe/ssz')
const {
  Tree,
  zeroNode,
  LeafNode,
  toGindex,
} = require('@darwinia/contracts-verify/src/imt/lib')

class IncrementalMerkleTree extends Tree {
  constructor(leaves) {
    super(zeroNode(32))
    this.depth = 32
    if (leaves) {
      leaves.map((leave, index) => {
        const gindex = toGindex(this.depth, BigInt(index));
        const newNode = LeafNode.fromRoot(leave);
        this.setNode(gindex, newNode);
      })
    }
  }

  root() {
    return this.rootNode.root
  }

  getSingleProof(i) {
    const gindex = toGindex(32, BigInt(i))
    return super.getSingleProof(gindex)
  }

  getSingleHexProof(i) {
    let proof = this.getSingleProof(i)
    return proof.map(toHexString)
  }
}

module.exports.IncrementalMerkleTree = IncrementalMerkleTree

// const ls = [Buffer.alloc(32, 1), Buffer.alloc(32, 2)]
// const t = new IncrementalMerkleTree(ls)
// console.log(toHexString(t.root()))
// console.log(t.getSingleHexProof(0))
