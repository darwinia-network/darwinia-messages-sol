// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./interfaces/IMsgport.sol";
import "./interfaces/IMessageReceiver.sol";
import "./interfaces/AbstractMessageAdapter.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract DefaultMsgport is IMsgport, Ownable2Step {
    address public adapterAddress;
    uint256 public defaultExecutionGas;

    function setAdapter(address _adapterAddress) external onlyOwner {
        adapterAddress = _adapterAddress;
    }

    function estimateFee(
        address _fromDappAddress,
        bytes memory _messagePayload,
        uint256 _executionGas, // 0 means using defaultExecutionGas
        uint256 _gasPrice
    ) external view returns (uint256) {
        return
            doEstimateFee(
                _fromDappAddress,
                _messagePayload,
                _executionGas,
                _gasPrice
            );
    }

    function doEstimateFee(
        address _fromDappAddress,
        bytes memory _messagePayload,
        uint256 _executionGas, // 0 means using defaultExecutionGas
        uint256 _gasPrice
    ) internal view returns (uint256) {
        AbstractMessageAdapter adapter = AbstractMessageAdapter(adapterAddress);

        // fee1: Get the relay fee.
        uint256 relayFee = adapter.getRelayFee(
            _fromDappAddress,
            _messagePayload
        );

        // fee2: Get the delivery gas. this gas used by lower level layer and msgport.
        uint256 deliveryGas = adapter.getDeliveryGas(
            _fromDappAddress,
            _messagePayload
        );

        // fee3: Get the message execution gas.
        uint256 executionGas = _executionGas == 0
            ? defaultExecutionGas
            : _executionGas;

        return relayFee + (deliveryGas + executionGas) * _gasPrice;
    }

    // called by Dapp.
    function send(
        address _toDappAddress,
        bytes memory _messagePayload,
        uint256 _executionGas, // 0 means using defaultExecutionGas,
        uint256 _gasPrice
    ) external payable returns (uint256) {
        uint256 fee = doEstimateFee(
            msg.sender,
            _messagePayload,
            _executionGas,
            _gasPrice
        );

        // check fee payed by caller is enough.
        uint256 paid = msg.value;
        require(paid >= fee, "!fee");

        // refund fee to caller if paid too much.
        if (paid > fee) {
            payable(msg.sender).transfer(paid - fee);
        }

        return
            AbstractMessageAdapter(adapterAddress).send{value: fee}(
                msg.sender,
                _toDappAddress,
                _messagePayload
            );
    }

    // called by adapter.
    //
    // catch the error if user's recv function failed with uncaught error.
    // store the message and error for the user to do something like retry.
    function recv(
        address _fromDappAddress,
        address _toDappAddress,
        bytes memory _messagePayload
    ) external {
        require(msg.sender == adapterAddress, "!adapter");
        try
            IMessageReceiver(_toDappAddress).recv(
                _fromDappAddress,
                _messagePayload
            )
        {} catch Error(string memory reason) {
            emit DappError(
                _fromDappAddress,
                _toDappAddress,
                _messagePayload,
                reason
            );
        } catch (bytes memory reason) {
            emit DappError(
                _fromDappAddress,
                _toDappAddress,
                _messagePayload,
                string(reason)
            );
        }
    }
}
