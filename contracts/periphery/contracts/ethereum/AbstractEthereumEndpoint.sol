// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IOutboundLane.sol";
import "../interfaces/IFeeMarket.sol";
import "../interfaces/ICrossChainFilter.sol";

abstract contract AbstractEthereumEndpoint {
    address public immutable TO_DARWINIA_OUTBOUND_LANE;
    address public immutable TO_DARWINIA_FEE_MARKET;
    address public remoteEndpoint;

    event DispatchCall(bytes call);

    constructor(address _toDarwiniaOutboundLane, address _toDarwiniaFeeMarket) {
        TO_DARWINIA_OUTBOUND_LANE = _toDarwiniaOutboundLane;
        TO_DARWINIA_FEE_MARKET = _toDarwiniaFeeMarket;
    }

    function fee() public view returns (uint256) {
        return IFeeMarket(TO_DARWINIA_FEE_MARKET).market_fee();
    }

    // Execute a darwinia remoteContract's function.
    // ethereum > darwinia
    function executeOnRemote(
        address remoteContractAddress,
        bytes memory call
    ) public payable returns (uint64 nonce) {
        uint256 paid = msg.value;
        uint256 marketFee = fee();
        require(paid >= marketFee, "!fee");
        if (paid > marketFee) {
            // refund fee to DAPP.
            // why use `call`? https://solidity-by-example.org/sending-ether/
            (bool sent, bytes memory data) = payable(msg.sender).call{
                value: paid - marketFee
            }("");
            require(sent, "!refund");
        }

        return
            IOutboundLane(TO_DARWINIA_OUTBOUND_LANE).send_message{
                value: marketFee
            }(remoteContractAddress, call);
    }

    // Execute a darwinia endpoint function.
    // ethereum > darwinia
    function executeOnRemoteEndpoint(
        bytes memory call
    ) public payable returns (uint64 nonce) {
        return executeOnRemote(remoteEndpoint, call);
    }

    // ethereum > darwinia(substrate)
    function dispatchOnRemote(
        bytes memory dispatchCall
    ) external payable returns (uint64 nonce) {
        bytes memory call = abi.encodeWithSignature(
            "dispatch(bytes)",
            dispatchCall
        );
        emit DispatchCall(call);
        return executeOnRemoteEndpoint(call);
    }

    // ethereum > darwinia > parachain
    //
    // Payment flow on ethereum:
    //   `ENDUSER` pay to `DAPP`,
    //      then `DAPP` pay to `DAPP ENDPOINT`,
    //        then `DAPP ENDPOINT` pay to `OUTBOUNDLANE`,
    //          then `OUTBOUNDLANE` pay to `RELAYER`
    function dispatchOnParachain(
        bytes2 paraId,
        bytes memory paraCall,
        uint64 weight,
        uint128 fungible
    ) external payable returns (uint64 nonce) {
        bytes memory call = abi.encodeWithSignature(
            "xcmTransactOnParachain(bytes2,bytes,uint64,uint128)",
            paraId,
            paraCall,
            weight,
            fungible
        );
        return executeOnRemoteEndpoint(call);
    }

    function _setRemoteEndpoint(address _remoteEndpoint) internal {
        remoteEndpoint = _remoteEndpoint;
    }
}
