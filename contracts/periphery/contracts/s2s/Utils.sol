// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library Utils {
    function revertIfFailed(
        bool _success,
        bytes memory _resultData,
        string memory _revertMsg
    ) internal pure {
        if (!_success) {
            if (_resultData.length > 0) {
                assembly {
                    let resultDataSize := mload(_resultData)
                    revert(add(32, _resultData), resultDataSize)
                }
            } else {
                revert(_revertMsg);
            }
        }
    }
}
