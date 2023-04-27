// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./interfaces/IMessageReceiver.sol";
import "./interfaces/IMessageGateway.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";

contract DarwiniaMessageHub is IMessageReceiver {
    bytes2 public immutable DARWINIA_PARAID;
    bytes2 public immutable SEND_CALL_INDEX;
    address public constant DISPATCH =
        0x0000000000000000000000000000000000000401;

    address public immutable GATEWAY_ADDRESS;

    constructor(
        bytes2 _darwiniaParaId,
        bytes2 _sendCallIndex,
        address _gatewayAddress
    ) {
        DARWINIA_PARAID = _darwiniaParaId;
        SEND_CALL_INDEX = _sendCallIndex;
        GATEWAY_ADDRESS = _gatewayAddress;
    }

    function fee() external view returns (uint256) {
        return IMessageGateway(GATEWAY_ADDRESS).estimateFee();
    }

    //////////////////////////
    // To Parachain
    //////////////////////////
    // message format:
    //  - paraId: bytes2
    //  - call: bytes
    //  - refTime: uint64
    //  - proofSize: uint64
    //  - fungible: uint128
    function recv(address _fromDappAddress, bytes calldata _message) external {
        (
            bytes2 paraId,
            bytes memory call,
            uint64 refTime,
            uint64 proofSize,
            uint128 fungible
        ) = abi.decode(_message, (bytes2, bytes, uint64, uint64, uint128));
        require(
            msg.sender == GATEWAY_ADDRESS,
            "DarwiniaMessageHub: only accept message from gateway"
        );

        transactOnParachain(
            paraId,
            _fromDappAddress,
            call,
            refTime,
            proofSize,
            fungible
        );
    }

    function transactOnParachain(
        bytes2 paraId,
        address fromDappAddress,
        bytes memory call,
        uint64 refTime,
        uint64 proofSize,
        uint128 fungible
    ) internal {
        bytes memory message = buildXcmPayload(
            DARWINIA_PARAID,
            fromDappAddress,
            call,
            refTime,
            proofSize,
            fungible
        );

        bytes memory polkadotXcmSendCall = abi.encodePacked(
            // call index of `polkadotXcm.send`
            SEND_CALL_INDEX,
            // dest: V2(01, X1(Parachain(ParaId)))
            hex"00010100",
            paraId,
            message
        );

        (bool success, bytes memory data) = DISPATCH.call(polkadotXcmSendCall);

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

    function buildXcmPayload(
        bytes2 fromParachain,
        address fromDappAddress,
        bytes memory call,
        uint64 refTime,
        uint64 proofSize,
        uint128 fungible
    ) internal pure returns (bytes memory) {
        bytes memory fungibleEncoded = ScaleCodec.encodeUintCompact(fungible);
        return
            abi.encodePacked(
                // XcmVersion + Instruction Length
                hex"0310",
                // DescendOrigin
                // --------------------------
                hex"0b010300",
                fromDappAddress,
                // WithdrawAsset
                // --------------------------
                hex"000400010200",
                fromParachain,
                hex"040500",
                fungibleEncoded,
                // BuyExecution
                // --------------------------
                hex"1300010200",
                fromParachain,
                hex"040500",
                fungibleEncoded,
                hex"00", // weight limit
                // Transact
                // --------------------------
                hex"0601",
                ScaleCodec.encodeUintCompact(refTime),
                ScaleCodec.encodeUintCompact(proofSize),
                ScaleCodec.encodeUintCompact(call.length),
                call
            );
    }

    //////////////////////////
    // To Ethereum
    //////////////////////////
    function send(
        address _toDappAddress, // address on Ethereum
        bytes calldata _message
    ) external payable returns (uint256 nonce) {
        uint256 paid = msg.value;
        IMessageGateway gateway = IMessageGateway(GATEWAY_ADDRESS);
        uint256 marketFee = gateway.estimateFee();
        require(paid >= marketFee, "the fee is insufficient");
        if (paid > marketFee) {
            // refund fee to DAPP.
            payable(msg.sender).transfer(paid - marketFee);
        }

        return gateway.send{value: marketFee}(_toDappAddress, _message);
    }
}
