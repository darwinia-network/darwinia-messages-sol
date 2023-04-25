// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IFeeMarket.sol";
import "./interfaces/IMessageGateway.sol";
import "./interfaces/IMessageReceiver.sol";
import "./interfaces/AbstractMessageAdapter.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract MessageGateway is IMessageGateway, Ownable2Step {
    mapping(uint16 => address) public adapterAddresses;
    uint16 public defaultAdapterId = 0;

    function addAdapter(
        uint16 _adapterId,
        address _adapterAddress
    ) external onlyOwner {
        // check adapter id is not used.
        require(adapterAddresses[_adapterId] == address(0), "adapter exists");

        adapterAddresses[_adapterId] = _adapterAddress;
        setDefaultAdapterId(_adapterId);
    }

    function setDefaultAdapterId(uint16 _adapterId) public onlyOwner {
        // check adapter id exists.
        require(
            adapterAddresses[_adapterId] != address(0),
            "adapter not exists"
        );

        defaultAdapterId = _adapterId;
    }

    function estimateFee() external view returns (uint256) {
        address adapterAddress = adapterAddresses[defaultAdapterId];
        AbstractMessageAdapter adapter = AbstractMessageAdapter(adapterAddress);
        return adapter.estimateFee();
    }

    function send(
        address remoteDappAddress,
        bytes memory message
    ) external payable returns (uint256) {
        address adapterAddress = adapterAddresses[defaultAdapterId];
        AbstractMessageAdapter adapter = AbstractMessageAdapter(adapterAddress);

        uint256 paid = msg.value;
        uint256 estimatedFee = adapter.estimateFee();
        require(paid >= estimatedFee, "!fee");

        // refund fee to caller if paid too much.
        if (paid > estimatedFee) {
            payable(msg.sender).transfer(paid - estimatedFee);
        }

        return
            adapter.send{value: estimatedFee}(
                msg.sender,
                remoteDappAddress,
                message
            );
    }
}
