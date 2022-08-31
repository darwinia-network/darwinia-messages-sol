// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../interfaces/IXcmUtils.sol";
import "../../Utils.sol";

library XcmUtils {
    function multilocationToAddress(
        IXcmUtils.Multilocation memory multilocation
    ) internal view returns (address) {
        // call multilocationToAddress(moonbeam's precompile)
        (
            bool success,
            bytes memory data
        ) = 0x000000000000000000000000000000000000080C.staticcall(
                abi.encodeWithSelector(
                    IXcmUtils.multilocationToAddress.selector,
                    multilocation
                )
            );

        Utils.revertIfFailed(success, data, "Multilocation to address failed");

        return Utils.bytesToAddress(data);
    }

    function deriveMoonbeamAddressFromAccountId(
        bytes memory _parachainId,
        bytes32 _accountId
    ) internal view returns (address) {
        // build multilocation
        bytes[] memory interior = new bytes[](2);
        interior[0] = _parachainId;
        interior[1] = abi.encodePacked(bytes1(0x01), _accountId, bytes1(0x00));
        IXcmUtils.Multilocation memory multilocation = IXcmUtils.Multilocation(
            1,
            interior
        );

        return multilocationToAddress(multilocation);
    }
}
