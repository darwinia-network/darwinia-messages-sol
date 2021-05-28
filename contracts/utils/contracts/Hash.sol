// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

// import "./Memory.sol";
import "./Blake2b.sol";

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
}
