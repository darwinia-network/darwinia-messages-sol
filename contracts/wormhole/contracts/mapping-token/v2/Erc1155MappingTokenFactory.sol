// SPDX-License-Identifier: MIT
// This is the Issuing Module(Mapping-token-factory) of the ethereum like bridge.
// We trust the inboundLane/outboundLane when we add them to the module.
// It means that each message from the inboundLane is verified correct and truthly from the sourceAccount.
// Only we need is to verify the sourceAccount is expected. And we add it to the Filter.

pragma solidity ^0.8.10;

import "../interfaces/IMessageCommitment.sol";
import "../interfaces/IErc1155MappingToken.sol";
import "../interfaces/IErc1155AttrSerializer.sol";
import "../interfaces/IErc1155Backing.sol";
import "./Erc1155MappingToken.sol";
import "./MappingTokenFactory.sol";

contract Erc1155MappingTokenFactory is MappingTokenFactory {
    struct UnconfirmedInfo {
        address sender;
        address mappingToken;
        uint256[] ids;
        uint256[] amounts;
    }
    mapping(uint256 => UnconfirmedInfo) public unlockRemoteUnconfirmed;

    event IssuingERC1155Created(address backingAddress, address originalToken, address mappingToken);
    event BurnAndWaitingConfirm(uint256 messageId, address sender, address recipient, address token, uint256[] ids, uint256[] amounts);
    event RemoteUnlockConfirmed(uint256 messageId, bool result);

    /**
     * @notice create new erc1155 mapping contract, this can only be called by inboundLane
     * @param backingAddress the backingAddress which send this message
     * @param originalToken the original token address
     * @param attrSerializer the serializer address of the attributes
     * @param bridgedChainName bridged chain name
     */
    function newErc1155Contract(
        address backingAddress,
        address originalToken,
        address attrSerializer,
        string memory bridgedChainName
    ) public onlyInBoundLane(backingAddress) whenNotPaused returns (address mappingToken) {
        // (bridgeChainId, backingAddress, originalToken) pack a unique new contract salt
        uint32 bridgedChainPosition = IMessageCommitment(msg.sender).bridgedChainPosition();
        bytes32 salt = keccak256(abi.encodePacked(bridgedChainPosition, backingAddress, originalToken));
        require(salt2MappingToken[salt] == address(0), "MappingTokenFactory:contract has been deployed");
        bytes memory bytecode = type(Erc1155MappingToken).creationCode;
        bytes memory bytecodeWithInitdata = abi.encodePacked(bytecode, abi.encode(bridgedChainName, attrSerializer));
        mappingToken = deploy(salt, bytecodeWithInitdata);
        // save the mapping tokens in an array so it can be listed
        allMappingTokens.push(mappingToken);
        // map the originToken to mappingInfo
        salt2MappingToken[salt] = mappingToken;
        // map the mappingToken to origin info
        mappingToken2OriginalInfo[mappingToken] = OriginalInfo(bridgedChainPosition, backingAddress, originalToken);
        emit IssuingERC1155Created(backingAddress, originalToken, mappingToken);
    }

    /**
     * @notice issue mapping token, only can be called by inboundLane
     * @param backingAddress the backingAddress which send this message
     * @param originalToken the original token address
     * @param recipient the recipient of the issued mapping token
     * @param ids the ids of the issued mapping tokens
     * @param attrs the serialized data of the original token's attributes
     */
    function issueMappingToken(
        address backingAddress,
        address originalToken,
        address recipient,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes[] calldata attrs
    ) public onlyInBoundLane(backingAddress) whenNotPaused {
        uint32 bridgedChainPosition = IMessageCommitment(msg.sender).bridgedChainPosition();
        bytes32 salt = keccak256(abi.encodePacked(bridgedChainPosition, backingAddress, originalToken));
        address mappingToken = salt2MappingToken[salt];
        require(mappingToken != address(0), "MappingTokenFactory:mapping token has not created");
        require(ids.length > 0, "MappingTokenFactory:can not receive empty ids");
        require(ids.length == attrs.length, "MappingTokenFactory:the length mismatch");
        IErc1155MappingToken(mappingToken).mintBatch(recipient, ids, amounts);
        address serializer = IErc1155MappingToken(mappingToken).attributeSerializer();
        deserializeAttrs(serializer, ids, attrs);
    }

    function deserializeAttrs(address serializer, uint256[] memory ids, bytes[] memory attrs) internal {
        for (uint idx = 0; idx < ids.length; idx++) {
            if (serializer != address(0)) {
                IErc1155AttrSerializer(serializer).deserialize(ids[idx], attrs[idx]);
            }
        }
    }

    /**
     * @notice burn mapping token and unlock remote original token, waiting for the confirm
     * @param bridgedLanePosition the bridged lane position to send the unlock message
     * @param mappingToken the burt mapping token address
     * @param recipient the recipient of the remote unlocked token
     * @param ids the ids of the burn and unlock
     */
    function burnAndRemoteUnlockWaitingConfirm(
        uint32 bridgedLanePosition,
        address mappingToken,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external payable whenNotPaused {
        require(ids.length > 0, "MappingTokenFactory:can not transfer empty id");
        OriginalInfo memory info = mappingToken2OriginalInfo[mappingToken];
        require(info.originalToken != address(0), "MappingTokenFactory:token is not created by factory");
        // Lock the fund in this before message on remote backing chain get dispatched successfully and burn finally
        // If remote backing chain unlock the origin token successfully, then this fund will be burned.
        // Otherwise, these tokens will be transfered back to the msg.sender.
        bytes[] memory attrs = new bytes[](ids.length);
        address serializer = IErc1155MappingToken(mappingToken).attributeSerializer();
        IERC1155(mappingToken).safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");
        for (uint256 idx = 0; idx < ids.length; idx++) {
            if (serializer != address(0)) {
                attrs[idx] = IErc1155AttrSerializer(serializer).serialize(ids[idx]);
            }
        }

        bytes memory unlockFromRemote = abi.encodeWithSelector(
            IErc1155Backing.unlockFromRemote.selector,
            address(this),
            info.originalToken,
            recipient,
            ids,
            amounts,
            attrs
        );
        uint256 messageId = _sendMessage(info.bridgedChainPosition, bridgedLanePosition, info.backingAddress, unlockFromRemote);
        unlockRemoteUnconfirmed[messageId] = UnconfirmedInfo(msg.sender, mappingToken, ids, amounts);
        emit BurnAndWaitingConfirm(messageId, msg.sender, recipient, mappingToken, ids, amounts);
    }

    /**
     * @notice this will be called when the burn and unlock from remote message confirmed
     * @param messageId the message id, is used to identify the unlocked message
     * @param result the result of the remote backing's unlock, if false, the mapping token need to transfer back to the user, otherwise burt
     */
    function on_messages_delivered(
        uint256 messageId,
        bool result
    ) external onlyOutBoundLane {
        UnconfirmedInfo memory info = unlockRemoteUnconfirmed[messageId];
        require(info.ids.length > 0 && info.sender != address(0) && info.mappingToken != address(0), "MappingTokenFactory:invalid unconfirmed message");
        if (result) {
            IErc1155MappingToken(info.mappingToken).burnBatch(info.ids, info.amounts);
        } else {
            IERC1155(info.mappingToken).safeBatchTransferFrom(address(this), info.sender, info.ids, info.amounts, "");
        }
        delete unlockRemoteUnconfirmed[messageId];
        emit RemoteUnlockConfirmed(messageId, result);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return Erc1155MappingTokenFactory.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return Erc1155MappingTokenFactory.onERC1155BatchReceived.selector;
    }
}

