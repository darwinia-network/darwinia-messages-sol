// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IXcmTransactor.sol";

contract DarwiniaEndpoint {
    address public constant XCM_TRANSACTOR = 0x0000000000000000000000000000000000000400;

    function executeOnAstar(address target, bytes memory call) external {
        transactThroughSigned(
            0x00000000,
            0x0000000000000000000000000000000000000400,
            600000, // TODO: How to calc weight
            call
        );
    }

    /////////////////////////////////////////////
    // INTERNAL FUNCTIONS
    /////////////////////////////////////////////
    function transactThroughSigned(
        bytes4 _tgtParachainId,
        address _feeLocationAddress,
        uint64 _tgtCallWeight,
        bytes memory _tgtCallEncoded
    ) internal {
        bytes[] memory interior = new bytes[](1);
        interior[0] = abi.encodePacked(hex"00", _tgtParachainId);
        IXcmTransactor.Multilocation memory dest = IXcmTransactor
            .Multilocation(1, interior);
        
        IXcmTransactor(XCM_TRANSACTOR).transactThroughSigned(
            dest,
            _feeLocationAddress,
            _tgtCallWeight,
            _tgtCallEncoded
        );
    }
}
