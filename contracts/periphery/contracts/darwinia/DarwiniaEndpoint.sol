// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IXcmTransactor.sol";
import "../interfaces/ICrossChainFilter.sol";
import "../interfaces/IOutboundLane.sol";
import "../interfaces/IFeeMarket.sol";
import "../s2s/types/PalletEthereumXcm.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./DarwiniaLib.sol";

contract DarwiniaEndpoint is ICrossChainFilter {
    address public constant DISPATCH =
        0x0000000000000000000000000000000000000401;
    bytes2 public immutable SEND_CALL_INDEX;
    bytes2 public immutable FROM_PARACHAIN;
    address public immutable TO_ETHEREUM_OUTBOUND_LANE;
    address public immutable TO_ETHEREUM_FEE_MARKET;

    constructor(
        bytes2 _sendCallIndex,
        bytes2 _fromParachain,
        address _toEthereumOutboundLane,
        address _toEthereumFeeMarket
    ) {
        SEND_CALL_INDEX = _sendCallIndex;
        FROM_PARACHAIN = _fromParachain;
        TO_ETHEREUM_OUTBOUND_LANE = _toEthereumOutboundLane;
        TO_ETHEREUM_FEE_MARKET = _toEthereumFeeMarket;
    }

    function dispatchOnParachain(
        bytes2 paraId,
        bytes memory dispatchCall,
        uint64 weight
    ) external {
        transactThroughSigned(paraId, dispatchCall, weight);
    }

    function executeOnEthereum(
        address target,
        bytes memory call
    ) external returns (uint64 nonce) {
        return
            IOutboundLane(TO_ETHEREUM_OUTBOUND_LANE).send_message{
                value: IFeeMarket(TO_ETHEREUM_FEE_MARKET).market_fee()
            }(target, call);
    }

    function cross_chain_filter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address sourceAccount,
        bytes calldata payload
    ) external view returns (bool) {
        return true;
    }

    /////////////////////////////////////////////
    // INTERNAL FUNCTIONS
    /////////////////////////////////////////////
    function transactThroughSigned(
        bytes2 toParachain,
        bytes memory call,
        uint64 weight
    ) internal {
        (bool success, bytes memory data) = DISPATCH.call(
            abi.encodePacked(
                // call index
                SEND_CALL_INDEX,
                // dest: V2(01, X1(Parachain(ParaId)))
                hex"00010100",
                toParachain,
                // message
                DarwiniaLib.xcmTransactOnParachain(
                    FROM_PARACHAIN,
                    call,
                    weight //  TODO: fix
                )
            )
        );

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
    }
}
