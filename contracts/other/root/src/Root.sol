// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts@4.8.2/access/Ownable2Step.sol";

contract Root is Ownable2Step {

    // @dev dispatch precompile address(0x0401)
    address public immutable DISPATCH_PRECOMPILE;

    constructor(address sudo, address dispatch) {
        _transferOwnership(sudo);
        DISPATCH_PRECOMPILE = dispatch;
    }

    function dispatch(bytes calldata data) external payable returns (bytes memory) {
        return execute(DISPATCH_PRECOMPILE, data);
    }

    function execute(address target, bytes calldata data) public payable onlyOwner returns (bytes memory) {
        (bool ok bytes memory out) = target.call{value: msg.value}(data);
        if (ok) {
            return out;
        } else {
            _revert(out, "!call");
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        if (returndata.length > 0) {
            assembly ("memory-safe") {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}
