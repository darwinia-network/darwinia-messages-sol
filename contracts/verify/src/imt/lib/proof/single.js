"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deserializeSingleProof = exports.serializeSingleProof = exports.computeSingleProofSerializedLength = exports.createNodeFromSingleProof = exports.createSingleProof = exports.ERR_INVALID_NAV = void 0;
const node_1 = require("../node");
const gindex_1 = require("../gindex");
exports.ERR_INVALID_NAV = "Invalid tree navigation";
function createSingleProof(rootNode, index) {
    const witnesses = [];
    let node = rootNode;
    for (const i of gindex_1.gindexIterator(index)) {
        if (i) {
            if (node.isLeaf())
                throw new Error(exports.ERR_INVALID_NAV);
            witnesses.push(node.left.root);
            node = node.right;
        }
        else {
            if (node.isLeaf())
                throw new Error(exports.ERR_INVALID_NAV);
            witnesses.push(node.right.root);
            node = node.left;
        }
    }
    return [node.root, witnesses.reverse()];
}
exports.createSingleProof = createSingleProof;
function createNodeFromSingleProof(gindex, leaf, witnesses) {
    let node = node_1.LeafNode.fromRoot(leaf);
    const w = witnesses.slice().reverse();
    while (gindex > 1) {
        const sibling = node_1.LeafNode.fromRoot(w.pop());
        if (gindex % BigInt(2) === BigInt(0)) {
            node = new node_1.BranchNode(node, sibling);
        }
        else {
            node = new node_1.BranchNode(sibling, node);
        }
        gindex = gindex / BigInt(2);
    }
    return node;
}
exports.createNodeFromSingleProof = createNodeFromSingleProof;
function computeSingleProofSerializedLength(witnesses) {
    return 1 + 2 + 32 + 2 + witnesses.length * 32;
}
exports.computeSingleProofSerializedLength = computeSingleProofSerializedLength;
function serializeSingleProof(output, byteOffset, gindex, leaf, witnesses) {
    const writer = new DataView(output.buffer, output.byteOffset, output.byteLength);
    writer.setUint16(byteOffset, Number(gindex), true);
    const leafStartIndex = byteOffset + 2;
    output.set(leaf, leafStartIndex);
    const witCountStartIndex = leafStartIndex + 32;
    writer.setUint16(witCountStartIndex, witnesses.length, true);
    const witnessesStartIndex = witCountStartIndex + 2;
    for (let i = 0; i < witnesses.length; i++) {
        output.set(witnesses[i], i * 32 + witnessesStartIndex);
    }
}
exports.serializeSingleProof = serializeSingleProof;
function deserializeSingleProof(data, byteOffset) {
    const reader = new DataView(data.buffer, data.byteOffset, data.byteLength);
    const gindex = reader.getUint16(byteOffset, true);
    const leafStartIndex = byteOffset + 2;
    const leaf = data.subarray(leafStartIndex, 32 + leafStartIndex);
    const witCountStartIndex = leafStartIndex + 32;
    const witCount = reader.getUint16(witCountStartIndex, true);
    const witnessesStartIndex = witCountStartIndex + 2;
    const witnesses = Array.from({ length: witCount }, (_, i) => data.subarray(i * 32 + witnessesStartIndex, (i + 1) * 32 + witnessesStartIndex));
    return [BigInt(gindex), leaf, witnesses];
}
exports.deserializeSingleProof = deserializeSingleProof;
