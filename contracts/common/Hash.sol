pragma solidity >=0.5.0 <0.6.0;

import "./Memory.sol";
import "../Blake2b.sol";

library Hash {
    function hash(bytes memory src) internal view returns (bytes memory des) {
        return Memory.toBytes(keccak256(src));
        // Blake2b.Instance memory instance = Blake2b.init(hex"", 32);
        // return instance.finalize(src);
    }
}
