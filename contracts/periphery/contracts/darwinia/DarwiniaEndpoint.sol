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
    bytes2 public immutable send = 0x2100;
    bytes2 public immutable fromParachain = 0xe520;

    address public constant TO_ETHEREUM_OUTBOUND_LANE =
        0xbA6c0608f68fA12600382Cd4D964DF9f090AA5B5;
    address public constant TO_ETHEREUM_FEE_MARKET =
        0x3553b673A47E66482b6eCFAE5bfc090Cc7eeEd27;

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
                send,
                // dest: V2(01, X1(Parachain(ParaId)))
                hex"00010100",
                toParachain,
                // message
                DarwiniaLib.xcmTransactOnParachain(
                    fromParachain,
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
