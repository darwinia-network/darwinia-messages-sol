// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../utils/rlp/RLPDecode.sol";
import "../utils/rlp/RLPEncode.sol";

library State {
    using RLPDecode for RLPDecode.RLPItem;

    struct EVMAccount {
        uint256 nonce;
        uint256 balance;
        bytes32 storage_root;
        bytes32 code_hash;
    }

    function toEVMAccount(bytes memory data) internal pure returns (EVMAccount memory) {
        RLPDecode.RLPItem[] memory account = RLPDecode.readList(data);

        return
            EVMAccount({
                nonce: account[0].readUint256(),
                balance: account[1].readUint256(),
                storage_root: account[2].readBytes32(),
                code_hash: account[3].readBytes32()
            });
    }
}
