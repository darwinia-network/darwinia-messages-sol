// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// This is the backing contract for Erc1155 token
// Before the new Erc1155 token registered, user should create two AttributesSerializer contract first
// One is deployed on the source chain to serialize the attributes of the token when lock_and_remote_issuing,
// and deserialize the attributes of the mapping token when unlock_from_remote
// The other is deployed on the target chain to deserialize the attributes of the token when the mapping token minted,
// and serialize the attributes of the mapping token when burn_and_unlock
// The AttributesSerializer must implement interfaces in IErc1155AttrSerializer.

import "@zeppelin-solidity-4.4.0/contracts/token/ERC1155/IERC1155.sol";
import "../interfaces/IErc1155AttrSerializer.sol";
import "../interfaces/IErc1155Backing.sol";
import "../interfaces/IErc1155MappingTokenFactory.sol";
import "./HelixApp.sol";

contract Erc1155TokenBacking is IErc1155Backing, HelixApp {
    struct LockedInfo {
        address token;
        address sender;
        uint256[] ids;
        uint256[] amounts;
    }

    struct TokenInfo {
        address token;
        address serializer;
    }

    // (messageId => tokenAddress)
    mapping(uint256 => TokenInfo) public registerMessages;

    // tokenAddress => reistered
    mapping(address => TokenInfo) public registeredTokens;

    // (messageId => lockedInfo)
    mapping(uint256 => LockedInfo) public lockMessages;

    event NewErc1155TokenRegistered(uint256 messageId, address token);
    event TokenLocked(uint256 messageId, address token, address recipient, uint256[] ids, uint256[] amounts);
    event TokenLockFinished(uint256 messageId, bool result);
    event TokenRegisterFinished(uint256 messageId, bool result);
    event TokenUnlocked(address token, address recipient, uint256[] ids, uint256[] amounts);

    /**
     * @notice reigister new erc1155 token to the bridge. Only owner can do this.
     * @param bridgedLanePosition the bridged lane positon, this register message will be delived to this lane position
     * @param token the original token address
     * @param attributesSerializer local serializer address of the token's attributes
     * @param remoteAttributesSerializer remote serializer address of the mapping token's attributes
     */
    function registerErc1155Token(
        uint32 bridgedLanePosition,
        address token,
        address attributesSerializer,
        address remoteAttributesSerializer
    ) external payable onlyOperator {
        require(registeredTokens[token].token == address(0), "Erc1155Backing:token has been registered");
        bytes memory newErc1155Contract = abi.encodeWithSelector(
            IErc1155MappingTokenFactory.newErc1155Contract.selector,
            address(this),
            token,
            remoteAttributesSerializer,
            thisChainName
        );
        uint256 messageId = _sendMessage(bridgedLanePosition, newErc1155Contract);
        registerMessages[messageId] = TokenInfo(token, attributesSerializer);
        emit NewErc1155TokenRegistered(messageId, token);
    }

    /**
     * @notice lock original token and issuing mapping token from bridged chain
     * @dev maybe some tokens will take some fee when transfer
     * @param bridgedLanePosition the bridged lane positon, this issuing message will be delived to this lane position
     * @param token the original token address
     * @param recipient the recipient who will receive the issued mapping token
     * @param ids ids of the locked token
     */
    function lockAndRemoteIssuing(
        uint32 bridgedLanePosition,
        address token,
        address recipient,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external payable whenNotPaused {
        TokenInfo memory info = registeredTokens[token];
        require(info.token != address(0), "Erc1155Backing:the token is not registed");

        bytes[] memory attrs = new bytes[](ids.length);
        IERC1155(token).safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");
        for (uint idx = 0; idx < ids.length; idx++) {
            if (info.serializer != address(0)) {
                attrs[idx] = IErc1155AttrSerializer(info.serializer).serialize(ids[idx]);
            }
        }

        bytes memory issueMappingToken = abi.encodeWithSelector(
            IErc1155MappingTokenFactory.issueMappingToken.selector,
            address(this),
            token,
            recipient,
            ids,
            amounts,
            attrs
        );
        uint256 messageId = _sendMessage(bridgedLanePosition, issueMappingToken);
        lockMessages[messageId] = LockedInfo(token, msg.sender, ids, amounts);
        emit TokenLocked(messageId, token, recipient, ids, amounts);
    }

    /**
     * @notice this will be called by outboundLane when the register/lock message confirmed
     * @param messageId message id to identify the register/lock message
     * @param result the result of the remote call
     */
    function on_messages_delivered(
        uint256 messageId,
        bool result
    ) external onlyOutBoundLane {
        LockedInfo memory lockedInfo = lockMessages[messageId];
        // it is lock message, if result is false, need to transfer back to the user, otherwise will be locked here
        if (lockedInfo.token != address(0)) {
            delete lockMessages[messageId];
            if (!result) {
                IERC1155(lockedInfo.token).safeBatchTransferFrom(address(this), lockedInfo.sender, lockedInfo.ids, lockedInfo.amounts, "");
            }
            emit TokenLockFinished(messageId, result);
            return;
        }
        TokenInfo memory info = registerMessages[messageId];
        // it is register message, if result is true, need to save the token
        if (info.token != address(0)) {
            delete registerMessages[messageId];
            if (result) {
                registeredTokens[info.token] = info;
            }
            emit TokenRegisterFinished(messageId, result);
        }
    }

    /**
     * @notice this will be called by inboundLane when the remote mapping token burned and want to unlock the original token
     * @param mappingTokenFactory the remote mapping token factory address
     * @param token the original token address
     * @param recipient the recipient who will receive the unlocked token
     * @param ids ids of the unlocked token
     * @param attrs the serialized data of the token's attributes may be updated from mapping token
     */
    function unlockFromRemote(
        address mappingTokenFactory,
        address token,
        address recipient,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes[] calldata attrs
    ) public onlyRemoteHelix(mappingTokenFactory) whenNotPaused {
        TokenInfo memory info = registeredTokens[token];
        require(info.token != address(0), "Erc1155Backing:the token is not registered");
        IERC1155(token).safeBatchTransferFrom(address(this), recipient, ids, amounts, "");
        for (uint idx = 0; idx < ids.length; idx++) {
            if (info.serializer != address(0)) {
                IErc1155AttrSerializer(info.serializer).deserialize(ids[idx], attrs[idx]);
            }
        }
        emit TokenUnlocked(token, recipient, ids, amounts);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return Erc1155TokenBacking.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return Erc1155TokenBacking.onERC1155BatchReceived.selector;
    }
}
 
