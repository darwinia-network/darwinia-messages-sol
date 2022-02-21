// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/utils/math/SafeMath.sol";
import "../interfaces/IErc721AttrSerializer.sol";
import "../interfaces/IErc721Backing.sol";
import "../interfaces/IErc721MappingTokenFactory.sol";
import "../interfaces/IERC721.sol";
import "./Backing.sol";

contract Erc721TokenBacking is IErc721Backing, Backing {
    using SafeMath for uint256;

    struct LockedInfo {
        address token;
        address sender;
        uint256[] ids;
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

    event NewErc721TokenRegistered(uint256 messageId, address token);
    event TokenLocked(uint256 messageId, address token, address recipient, uint256[] ids);
    event TokenLockFinished(uint256 messageId, bool result);
    event TokenRegisterFinished(uint256 messageId, bool result);
    event TokenUnlocked(address token, address recipient, uint256[] ids);

    /**
     * @notice reigister new erc721 token to the bridge. Only owner can do this.
     * @param bridgedLanePosition the bridged lane positon, this register message will be delived to this lane position
     * @param token the original token address
     * @param name the name of the original token
     * @param symbol the symbol of the original token
     */
    function registerErc721Token(
        uint32 tokenType,
        uint32 bridgedLanePosition,
        address token,
        string memory name,
        string memory symbol,
        address attributesSerializer
    ) external payable onlyOperatorOrOwner {
        require(registeredTokens[token].token == address(0), "Backing:token has been registered");
        bytes memory newErc721Contract = abi.encodeWithSelector(
            IErc721MappingTokenFactory.newErc721Contract.selector,
            address(this),
            tokenType,
            token,
            thisChainName,
            name,
            symbol
        );
        uint256 messageId = sendMessage(bridgedLanePosition, remoteMappingTokenFactory, newErc721Contract);
        registerMessages[messageId] = TokenInfo(token, attributesSerializer);
        emit NewErc721TokenRegistered(messageId, token);
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
        uint256[] calldata ids
    ) external payable whenNotPaused {
        TokenInfo memory info = registeredTokens[token];
        require(info.token != address(0), "Backing:the token is not registed");

        bytes[] memory attrs = new bytes[](ids.length);
        for (uint idx = 0; idx < ids.length; idx++) {
            IERC721(token).transferFrom(msg.sender, address(this), ids[idx]);
            if (info.serializer != address(0)) {
                attrs[idx] = IErc721AttrSerializer(info.serializer).Serialize(ids[idx]);
            }
        }

        bytes memory issueMappingToken = abi.encodeWithSelector(
            IErc721MappingTokenFactory.issueMappingToken.selector,
            address(this),
            token,
            recipient,
            ids,
            attrs
        );
        uint256 messageId = sendMessage(bridgedLanePosition, remoteMappingTokenFactory, issueMappingToken);
        lockMessages[messageId] = LockedInfo(token, msg.sender, ids);
        emit TokenLocked(messageId, token, recipient, ids);
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
                for (uint idx = 0; idx < lockedInfo.ids.length; idx++) {
                    IERC721(lockedInfo.token).transferFrom(address(this), lockedInfo.sender, lockedInfo.ids[idx]);
                }
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
     * @param token the original token address
     * @param recipient the recipient who will receive the unlocked token
     * @param ids ids of the unlocked token
     */
    function unlockFromRemote(
        address mappingTokenFactory,
        address token,
        address recipient,
        uint256[] calldata ids,
        bytes[] calldata attrs
    ) public onlyInBoundLane(mappingTokenFactory) whenNotPaused {
        TokenInfo memory info = registeredTokens[token];
        require(info.token != address(0), "the token is not registered");
        for (uint idx = 0; idx < ids.length; idx++) {
            IERC721(token).transferFrom(address(this), recipient, ids[idx]);
            if (info.serializer != address(0)) {
                IErc721AttrSerializer(info.serializer).Deserialize(ids[idx], attrs[idx]);
            }
        }
        emit TokenUnlocked(token, recipient, ids);
    }
}
 
