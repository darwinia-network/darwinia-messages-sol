// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../utils/RLPDecode.sol";
import "../utils/RLPEncode.sol";

library State {
    using RLPDecode for RLPDecode.RLPItem;
    using RLPDecode for RLPDecode.Iterator;

    struct Account {
        uint256 nonce;
        uint256 balance;
        bytes32 storage_root;
        bytes32 code_hash;
    }

    function toAccount(bytes memory data) internal pure returns (Account memory account) {
        RLPDecode.Iterator memory it = RLPDecode.toRlpItem(data).iterator();

        uint256 idx;
        while (it.hasNext()) {
            if (idx == 0) account.nonce = it.next().toUint();
            else if (idx == 1) account.balance = it.next().toUint();
            else if (idx == 2) account.storage_root = toBytes32(it.next().toBytes());
            else if (idx == 3) account.code_hash = toBytes32(it.next().toBytes());
            else it.next();
            idx++;
        }
    }

    function toBytes32(bytes memory data) internal pure returns (bytes32 _data) {
        assembly {
            _data := mload(add(data, 32))
        }
    }

}
