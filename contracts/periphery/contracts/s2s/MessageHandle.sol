// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./AccessController.sol";
import "./SmartChainXLib.sol";
import "./types/PalletEthereum.sol";

contract MessageHandle is AccessController {
    bytes4 public laneId;

    address public tgtHandle;
    // target chain's `message_transact` call index
    bytes2 public tgtMessageTransactCallIndex;
    // precompile addresses
    address public srcStorageAddress;
    address public srcDispatchAddress;
    // bridge info
    bytes2 public srcSendMessageCallIndex;
    // readonly storage keys
    bytes32 public srcStorageKeyForMarketFee;
    bytes32 public srcStorageKeyForLatestNonce;
    // 1 gas ~= 40_000 weight.
    uint64 public tgtWeightPerGas = 40_000;

    address public srcHandle;
    // source chain id
    bytes4 public srcChainId;
    // target smart chain id
    uint64 public tgtSmartChainId;
    // source chain message sender, derived from srcHandle
    address public derivedMessageSender;
    // precompile addresses
    address public tgtStorageAddress;
    // readonly storage keys
    bytes32 public tgtStorageKeyForLastDeliveredNonce;

    constructor() {
        _initialize(msg.sender);
    }

    function setLaneId(bytes4 _laneId) external onlyAdmin {
        laneId = _laneId;
    }

    ///////////////////////////////
    // Source
    ///////////////////////////////
    // External functions
    function remoteExecute(
        uint32 tgtSpecVersion,
        address callReceiver,
        bytes calldata callPayload,
        uint256 gasLimit
    ) external onlyCaller payable returns (uint64) {
        bytes memory input = abi.encodeWithSelector(
            this.execute.selector,
            callReceiver,
            callPayload
        );

        return _remoteTransact(tgtSpecVersion, input, gasLimit);
    }

    function fee() public view returns (uint256) {
        return
            SmartChainXLib.marketFee(
                srcStorageAddress,
                srcStorageKeyForMarketFee
            );
    }

    function setTgtHandle(address _tgtHandle) external onlyAdmin {
        tgtHandle = _tgtHandle;
    }

    function setTgtMessageTransactCallIndex(bytes2 _tgtMessageTransactCallIndex)
        external
        onlyAdmin
    {
        tgtMessageTransactCallIndex = _tgtMessageTransactCallIndex;
    }

    function setSrcStorageAddress(address _srcStorageAddress)
        external
        onlyAdmin
    {
        srcStorageAddress = _srcStorageAddress;
    }

    function setSrcDispatchAddress(address _srcDispatchAddress)
        external
        onlyAdmin
    {
        srcDispatchAddress = _srcDispatchAddress;
    }

    function setSrcSendMessageCallIndex(bytes2 _srcSendMessageCallIndex)
        external
        onlyAdmin
    {
        srcSendMessageCallIndex = _srcSendMessageCallIndex;
    }

    function setSrcStorageKeyForMarketFee(bytes32 _srcStorageKeyForMarketFee)
        external
        onlyAdmin
    {
        srcStorageKeyForMarketFee = _srcStorageKeyForMarketFee;
    }

    function setSrcStorageKeyForLatestNonce(
        bytes32 _srcStorageKeyForLatestNonce
    ) external onlyAdmin {
        srcStorageKeyForLatestNonce = _srcStorageKeyForLatestNonce;
    }

    function setSrcStorageKeyForLatestNonce(
        uint64 _tgtWeightPerGas
    ) external onlyAdmin {
        tgtWeightPerGas = _tgtWeightPerGas;
    }

    // Internal functions
    function _remoteTransact(
        uint32 tgtSpecVersion,
        bytes memory input,
        uint256 gasLimit
    ) internal returns (uint64) {
        PalletEthereum.MessageTransactCall memory call = PalletEthereum
            .MessageTransactCall(
                // the call index of message_transact
                tgtMessageTransactCallIndex,
                // the evm transaction to transact
                PalletEthereum.buildTransactionV2ForMessageTransact(
                    gasLimit,
                    tgtHandle,
                    tgtSmartChainId,
                    input
                )
            );
        bytes memory callEncoded = PalletEthereum.encodeMessageTransactCall(
            call
        );
        uint64 weight = uint64(gasLimit * tgtWeightPerGas);

        return
            SmartChainXLib.sendMessage(
                srcStorageAddress,
                srcDispatchAddress,
                srcStorageKeyForMarketFee,
                srcStorageKeyForLatestNonce,
                srcSendMessageCallIndex,
                laneId,
                tgtSpecVersion,
                callEncoded,
                weight
            );
    }

    ///////////////////////////////
    // Target
    ///////////////////////////////
    modifier onlyMessageSender() {
        require(
            derivedMessageSender == msg.sender,
            "MessageHandle: Invalid sender"
        );
        _;
    }

    function execute(address callReceiver, bytes calldata callPayload)
        external
        onlyMessageSender
        whenNotPaused
    {
        require(
            hasRole(CALLER_ROLE, callReceiver),
            "MessageHandle: Unauthorized receiver"
        );
        (bool success, ) = callReceiver.call(callPayload);
        require(success, "MessageHandle: Call execution failed");
    }

    function latestMessageNonce() public view returns (uint256) {
        return
            SmartChainXLib.lastDeliveredNonce(
                tgtStorageAddress,
                tgtStorageKeyForLastDeliveredNonce,
                laneId
            );
    }

    function setSrcHandle(address _srcHandle) external onlyAdmin {
        srcHandle = _srcHandle;
        derivedMessageSender = SmartChainXLib.deriveSenderFromRemote(
            srcChainId,
            srcHandle
        );
    }

    function setSrcChainId(bytes4 _srcChainId) external onlyAdmin {
        srcChainId = _srcChainId;
    }

    function setTgtSmartChainId(uint64 _tgtSmartChainId) external onlyAdmin {
        tgtSmartChainId = _tgtSmartChainId;
    }

    function setTgtStorageAddress(address _tgtStorageAddress)
        external
        onlyAdmin
    {
        tgtStorageAddress = _tgtStorageAddress;
    }

    function setTgtStorageKeyForLastDeliveredNonce(
        bytes32 _tgtStorageKeyForLastDeliveredNonce
    ) external onlyAdmin {
        tgtStorageKeyForLastDeliveredNonce = _tgtStorageKeyForLastDeliveredNonce;
    }
}
