// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./share/SystemCalls.sol";

library DarwiniaCalls {
    function system_remark(bytes memory _remark)
        internal
        pure
        returns (bytes memory, uint64)
    {
        return SystemCalls.remark(_remark);
    }

    function system_remarkWithEvent(bytes memory _remark)
        internal
        pure
        returns (bytes memory, uint64)
    {
        return SystemCalls.remarkWithEvent(_remark);
    }
}
