// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IFeeMarket.sol";
import "./interfaces/IMessageGateway.sol";
import "./interfaces/IMessageReceiver.sol";
import "./interfaces/AbstractMessageAdapter.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract MessageGateway is IMessageGateway, Ownable2Step {
    mapping(uint16 => address) public adapterAddresses;

    function setAdapterAddress(
        uint16 _adapterId,
        address _adapterAddress
    ) external onlyOwner {
        // check adapter id is not used.
        require(adapterAddresses[_adapterId] == address(0), "!adapterId");

        adapterAddresses[_adapterId] = _adapterAddress;
    }

    function removeAdapterAddress(uint16 _adapterId) external onlyOwner {
        delete adapterAddresses[_adapterId];
    }

    function send(
        uint16 adapterId,
        address remoteDappAddress,
        bytes memory message
    ) external payable returns (uint256) {
        address adapterAddress = adapterAddresses[adapterId];
        AbstractMessageAdapter adapter = AbstractMessageAdapter(adapterAddress);

        uint256 paid = msg.value;
        uint256 estimateFee = adapter.estimateFee();
        require(paid >= estimateFee, "!fee");

        // refund fee to caller if paid too much.
        if (paid > estimateFee) {
            payable(msg.sender).transfer(paid - estimateFee);
        }

        return
            adapter.send{value: estimateFee}(
                msg.sender,
                remoteDappAddress,
                message
            );
    }
}
