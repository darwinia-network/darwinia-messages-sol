// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./IXcmTransactorV1.sol";
import "../../Utils.sol";

library XcmTransactorV1 {
    address public constant precompileAddress =
        0x0000000000000000000000000000000000000806;

    function transactThroughSigned(
        IXcmTransactorV1.Multilocation memory dest,
        address feeLocationAddress,
        uint64 weight,
        bytes memory call
    ) external view {
        (bool success, bytes memory data) = precompileAddress.staticcall(
            abi.encodeWithSelector(
                IXcmTransactorV1.transactThroughSigned.selector,
                dest,
                feeLocationAddress,
                weight,
                call
            )
        );

        Utils.revertIfFailed(success, data, "Multilocation to address failed");
    }
}
