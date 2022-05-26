// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../spec/ChainMessagePosition.sol";
import "../common/StorageVerifier.sol";

interface IBSC {
    function state_root() external view returns (bytes32);
}

contract BSCLightClient is StorageVerifier {
    // address(0x1a)
    address private immutable BSC_PRECOMPILE;

    constructor(address bsc_precompile) StorageVerifier(uint32(ChainMessagePosition.BSC), 0, 1, 2) {
        BSC_PRECOMPILE = bsc_precompile;
    }

    function state_root() public view override returns (bytes32 root) {
        (bool ok, bytes memory out) = BSC_PRECOMPILE.staticcall(abi.encodeWithSelector(IBSC.state_root.selector));
        if (ok) {
            if (out.length == 32) {
                root = abi.decode(out, (bytes32));
            }
        } else {
            if (out.length > 0) {
                assembly {
                    let returndata_size := mload(out)
                    revert(add(32, out), returndata_size)
                }
            } else {
                revert("!call");
            }
        }
    }
}
