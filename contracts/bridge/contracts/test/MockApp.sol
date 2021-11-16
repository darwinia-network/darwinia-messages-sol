// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "../ethereum/v2/interfaces/ICrossChainFilter.sol";

contract MockApp is ICrossChainFilter {
    event Unlocked(bytes32 from, address to, uint256 amount);
    function unlock(bytes32 polkdotSender, address recipient, uint256 amount) public {
        emit Unlocked(polkdotSender, recipient, amount);
    }

    function crossChainFilter(address sourceAccount, bytes memory) public override view returns (bool) {
        require(sourceAccount == address(1), "invalid source account");
        return true;
    }
}
