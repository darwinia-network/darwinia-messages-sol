// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IXcmTransactor.sol";
import "../interfaces/ICrossChainFilter.sol";
import "../interfaces/IOutboundLane.sol";
import "../interfaces/IFeeMarket.sol";
import "../s2s/types/PalletEthereumXcm.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./DarwiniaLib.sol";

// Relayer call InboundLane
//   InboundLane call xcmTransactOnParachain
//     xcmTransactOnParaChain dispatch polkadotXcm.send
abstract contract AbstractDarwiniaEndpoint is ICrossChainFilter {
    address public constant DISPATCH =
        0x0000000000000000000000000000000000000401;
    bytes2 public immutable SEND_CALL_INDEX;
    bytes2 public immutable DARWINIA_PARAID;
    address public immutable TO_ETHEREUM_OUTBOUND_LANE;
    address public immutable TO_ETHEREUM_FEE_MARKET;

    event Dispatched(bytes call);

    constructor(
        bytes2 _sendCallIndex,
        bytes2 _darwiniaParaId,
        address _toEthereumOutboundLane,
        address _toEthereumFeeMarket
    ) {
        SEND_CALL_INDEX = _sendCallIndex;
        DARWINIA_PARAID = _darwiniaParaId;
        TO_ETHEREUM_OUTBOUND_LANE = _toEthereumOutboundLane;
        TO_ETHEREUM_FEE_MARKET = _toEthereumFeeMarket;
    }

    function fee() public view returns (uint256) {
        return IFeeMarket(TO_ETHEREUM_FEE_MARKET).market_fee();
    }

    event EthereumCallSent(address, bytes);

    //////////////////////////
    // To Ethereum
    //////////////////////////
    // Call by parachain dapp.
    // Used in `parachain > darwinia > ethereum`
    function executeOnEthereum(
        address target,
        bytes memory call
    ) external payable returns (uint64 nonce) {
        uint256 paid = msg.value;
        uint256 marketFee = fee();
        require(paid >= marketFee, "the fee is not enough");

        uint64 nonce = IOutboundLane(TO_ETHEREUM_OUTBOUND_LANE).send_message{
            value: marketFee
        }(target, call);

        emit EthereumCallSent(target, call);
        return nonce;
    }

    //////////////////////////
    // To Parachain
    //////////////////////////
    // Call by ethereum dapp.
    // Used in `ethereum > darwinia > parachain`
    function xcmTransactOnParachain(
        bytes2 toParachain,
        bytes memory call,
        uint64 weight,
        uint128 fungible
    ) external {
        bytes memory message = DarwiniaLib.buildXcmTransactMessage(
            DARWINIA_PARAID,
            call,
            weight,
            fungible
        );

        bytes memory polkadotXcmSendCall = abi.encodePacked(
            // call index of `polkadotXcm.send`
            SEND_CALL_INDEX,
            // dest: V2(01, X1(Parachain(ParaId)))
            hex"00010100",
            toParachain,
            message
        );

        dispatch(polkadotXcmSendCall);
    }

    // Call by ethereum dapp.
    // Used in `ethereum > darwinia`
    function dispatch(bytes memory call) public {
        (bool success, bytes memory data) = DISPATCH.call(call);

        if (!success) {
            if (data.length > 0) {
                assembly {
                    let resultDataSize := mload(data)
                    revert(add(32, data), resultDataSize)
                }
            } else {
                revert("!dispatch");
            }
        }

        emit Dispatched(call);
    }
}
