"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.digest64HashObjects = exports.digest2Bytes32 = exports.digest64 = exports.SHA256 = exports.hashObjectToByteArray = exports.byteArrayToHashObject = void 0;
const hashObject_1 = require("./hashObject");
Object.defineProperty(exports, "byteArrayToHashObject", { enumerable: true, get: function () { return hashObject_1.byteArrayToHashObject; } });
Object.defineProperty(exports, "hashObjectToByteArray", { enumerable: true, get: function () { return hashObject_1.hashObjectToByteArray; } });
const sha3_1 = require("@noble/hashes/sha3");
function digest64(data) {
    if (data.length === 64) {
        const output = new Uint8Array(32);
        output.set((0, sha3_1.keccak_256)(data));
        return output;
    }
    throw new Error("InvalidLengthForDigest64");
}
exports.digest64 = digest64;
function digest2Bytes32(bytes1, bytes2) {
    if (bytes1.length === 32 && bytes2.length === 32) {
        const input = new Uint8Array(64);
        input.set(bytes1);
        input.set(bytes2, 32);
        const output = new Uint8Array(32);
        output.set((0, sha3_1.keccak_256)(input));
        return output;
    }
    throw new Error("InvalidLengthForDigest64");
}
exports.digest2Bytes32 = digest2Bytes32;
/**
 * Digest 2 objects, each has 8 properties from h0 to h7.
 * The performance is a little bit better than digest64 due to the use of Uint32Array
 * and the memory is a little bit better than digest64 due to no temporary Uint8Array.
 * @returns
 */
function digest64HashObjects(obj1, obj2) {
    const input1 = new Uint8Array(32);
    const input2 = new Uint8Array(32);
    (0, hashObject_1.hashObjectToByteArray)(obj1, input1, 0);
    (0, hashObject_1.hashObjectToByteArray)(obj2, input2, 0);
    const output = digest2Bytes32(input1, input2);
    return (0, hashObject_1.byteArrayToHashObject)(output);
}
exports.digest64HashObjects = digest64HashObjects;
//# sourceMappingURL=index.js.map
