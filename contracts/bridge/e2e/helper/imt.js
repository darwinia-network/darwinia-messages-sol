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

}

module.exports.IncrementalMerkleTree = IncrementalMerkleTree

// const ls = [Buffer.alloc(32, 1), Buffer.alloc(32, 2)]
// const t = new IncrementalMerkleTree(ls)
// console.log(toHex(t.root()))
// const i = toGindex(32, BigInt(0))
// const p = t.getSingleProof(i)
// p.map(x => {
//   console.log(toHex(x))
// })

// function toHex(bytes) {
//   return Buffer.from(bytes).toString("hex");
// }
