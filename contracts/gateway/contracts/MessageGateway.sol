// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IFeeMarket.sol";
import "./interfaces/IMessageGateway.sol";
import "./interfaces/IMessageReceiver.sol";
import "./interfaces/AbstractMessageAdapter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MessageGateway is IMessageGateway {
    address creator;
    // TODO: mapping to support multiple adapters.
    address public adapterAddress;

    constructor() {
        creator = msg.sender;
    }

    // TODO: more pratical permission control.
    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    function setAdapterAddress(address _adapterAddress) external onlyCreator {
        adapterAddress = _adapterAddress;
    }

    function send(
        address remoteDappAddress,
        bytes memory message
    ) external payable returns (uint256) {
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
