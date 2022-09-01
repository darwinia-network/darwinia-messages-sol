// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./IXcmTransactorV2.sol";
import "../../Utils.sol";

library XcmTransactorV2 {
    address public constant precompileAddress =
        0x000000000000000000000000000000000000080D;

    function transactThroughSigned(
        IXcmTransactorV2.Multilocation memory dest,
        address feeLocationAddress,
        uint64 weight,
        bytes memory call,
        uint256 feeAmount,
        uint64 overallWeight
    ) external view {
        (bool success, bytes memory data) = precompileAddress.staticcall(
            abi.encodeWithSelector(
                IXcmTransactorV2.transactThroughSigned.selector,
                dest,
                feeLocationAddress,
                weight,
                call,
                feeAmount,
                overallWeight
            )
        );

        Utils.revertIfFailed(success, data, "Multilocation to address failed");
    }
}
