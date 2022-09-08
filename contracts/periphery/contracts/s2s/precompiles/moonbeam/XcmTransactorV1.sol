// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./IXcmTransactorV1.sol";
import "../../Utils.sol";

library XcmTransactorV1 {
    address public constant precompileAddress =
        0x0000000000000000000000000000000000000806;

    function transactThroughSigned(
        bytes4 _tgtParachainId,
        address _feeLocationAddress,
        uint64 _tgtCallWeight,
        bytes memory _tgtCallEncoded
    ) internal {
        bytes[] memory interior = new bytes[](1);
        interior[0] = abi.encodePacked(hex"00", _tgtParachainId);
        IXcmTransactorV1.Multilocation memory dest = IXcmTransactorV1
            .Multilocation(1, interior);
        
        IXcmTransactorV1(precompileAddress).transactThroughSigned(
            dest,
            _feeLocationAddress,
            _tgtCallWeight,
            _tgtCallEncoded
        );
    }
}
