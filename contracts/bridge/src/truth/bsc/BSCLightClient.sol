// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../interfaces/ISubStateStorage.sol";
import "../../spec/ChainMessagePosition.sol";
import "../common/StorageVerifier.sol";

interface IBSC {
    function state_root() external view returns (bytes32);
}

contract BSCLightClient is StorageVerifier {
    address private immutable STORAGE_PRECOMPILE = address(0x0400);
    // subalfred storage-key --prefix Bsc --item FinalizedCheckpoint
    bytes32 private immutable BSC_FINALIZED_CHECKPOINT_KEY = 0xdeeff83c81d2e28f78ad5890b33244d67d2d5aca142f290829575a29c215c204;

    constructor() StorageVerifier(uint32(ChainMessagePosition.BSC), 0, 1, 2) {}

    function state_root() public view override returns (bytes32 root) {
        bytes memory finalized_header = state_storage(abi.encodePacked(BSC_FINALIZED_CHECKPOINT_KEY));
        return decode_state_root_from_header(finalized_header);
    }

    function decode_state_root_from_header(bytes memory header) internal pure returns (bytes32 root) {
        require(header.length > 116, "!header");
        assembly {
            root := mload(add(add(header, 0x20), 0x54))
        }
    }

    function state_storage(bytes memory key) internal view returns (bytes memory value) {
        (bool ok, bytes memory out) = STORAGE_PRECOMPILE.staticcall(
            abi.encodeWithSelector(
                ISubStateStorage.state_storage.selector,
                key
            )
        );
        if (ok) {
            return out;
        } else {
            if (out.length > 0) {
                assembly {
                    let returndata_size := mload(out)
                    revert(add(32, out), returndata_size)
                }
            } else {
                revert("!state_storage");
            }
        }
    }
}
