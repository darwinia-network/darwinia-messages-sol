// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./share/SystemCalls.sol";

library DarwiniaCalls {
    function system_remark(bytes memory remark)
        internal
        pure
        returns (bytes memory, uint64)
    {
        return SystemCalls.remark(remark);
    }

    function system_remarkWithEvent(bytes memory remark)
        internal
        pure
        returns (bytes memory, uint64)
    {
        return SystemCalls.remarkWithEvent(remark);
    }
}
