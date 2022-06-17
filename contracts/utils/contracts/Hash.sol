// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

// import "./Memory.sol";
import "./Blake2b.sol";
import "./Bytes.sol";

library Hash {

    using Blake2b for Blake2b.Instance;

    // function hash(bytes memory src) internal view returns (bytes memory des) {
    //     return Memory.toBytes(keccak256(src));
        // Blake2b.Instance memory instance = Blake2b.init(hex"", 32);
        // return instance.finalize(src);
    // }

    function blake2bHash(bytes memory src) internal view returns (bytes32 des) {
        // return keccak256(src);
        Blake2b.Instance memory instance = Blake2b.init(hex"", 32);
        return abi.decode(instance.finalize(src), (bytes32));
    }

    // Blake2_128
    function blake2b128(bytes memory src) internal view returns (bytes16 des) {
        Blake2b.Instance memory instance = Blake2b.init(hex"", 16);
        return Bytes.toBytes16(instance.finalize(src), 0);
    }

    // Blake2_128Concat
    function blake2b128Concat(bytes memory src) internal view returns (bytes memory) {
        bytes16 out = blake2b128(src);
        return abi.encodePacked(out, src);
    }
}
