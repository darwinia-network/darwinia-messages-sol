// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IXcmTransactor.sol";
import "../interfaces/ICrossChainFilter.sol";
import "../interfaces/IOutboundLane.sol";
import "../interfaces/IFeeMarket.sol";
import "../s2s/types/PalletEthereumXcm.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./DarwiniaLib.sol";

abstract contract AbstractDarwiniaEndpoint is ICrossChainFilter {
    address public constant DISPATCH =
        0x0000000000000000000000000000000000000401;
    bytes2 public immutable SEND_CALL_INDEX;
    bytes2 public immutable DARWINIA_PARAID;
    address public immutable TO_ETHEREUM_OUTBOUND_LANE;
    address public immutable TO_ETHEREUM_FEE_MARKET;

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

    // Call by parachain dapp.
    // Used in `parachain > darwinia > ethereum`
    function executeOnEthereum(
        address target,
        bytes memory call
    ) external returns (uint64 nonce) {
        return
            IOutboundLane(TO_ETHEREUM_OUTBOUND_LANE).send_message{
                value: IFeeMarket(TO_ETHEREUM_FEE_MARKET).market_fee()
            }(target, call);
    }

    // Call by ethereum dapp.
    // Used in `ethereum > darwinia > parachain`
    function xcmTransactOnParachain(
        bytes2 toParachain,
        bytes memory call,
        uint64 weight,
        uint128 fungible
    ) external {
        (bool success, bytes memory data) = DISPATCH.call(
            abi.encodePacked(
                // call index of `polkadotXcm.send`
                SEND_CALL_INDEX,
                // dest: V2(01, X1(Parachain(ParaId)))
                hex"00010100",
                toParachain,
                // message
                DarwiniaLib.buildXcmTransactMessage(
                    DARWINIA_PARAID,
                    call,
                    weight,
                    fungible
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
