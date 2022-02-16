// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/utils/math/SafeMath.sol";
import "../../utils/DailyLimit.sol";
import "../interfaces/IBacking.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IGuard.sol";
import "../interfaces/IInboundLane.sol";
import "../interfaces/IMappingTokenFactory.sol";
import "./Backing.sol";

contract FungibleTokenBacking is DailyLimit, IBacking, Backing {
    using SafeMath for uint256;
    struct LockedInfo {
        address token;
        address sender;
        uint256 amount;
    }
    uint32 public constant NATIVE_TOKEN_TYPE = 0;
    uint32 public constant ERC20_TOKEN_TYPE = 1;
    address public guard;

    // (messageId => lockedInfo)
    mapping(uint256 => LockedInfo) public lockMessages;

    event NewErc20TokenRegistered(uint256 messageId, address token);
    event TokenLocked(uint256 messageId, address token, address recipient, uint256 amount);
    event TokenLockFinished(uint256 messageId, bool result);
    event TokenRegisterFinished(uint256 messageId, bool result);
    event TokenUnlocked(address token, address recipient, uint256 amount);

    function changeDailyLimit(address mappingToken, uint amount) public onlyOwner  {
        _changeDailyLimit(mappingToken, amount);
    }

    function updateGuard(address newGuard) external onlyOwner {
        guard = newGuard;
    }

    /**
     * @notice reigister new erc20 token to the bridge. Only owner can do this.
     * @param bridgedLanePosition the bridged lane positon, this register message will be delived to this lane position
     * @param token the original token address
     * @param name the name of the original token
     * @param symbol the symbol of the original token
     * @param decimals the decimals of the original token
     */
    function registerErc20Token(
        uint32 bridgedLanePosition,
        address token,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external payable onlyOperatorOrOwner {
        require(registeredTokens[token] == false, "Backing:token has been registered");

        bytes memory newErc20Contract = abi.encodeWithSelector(
            IMappingTokenFactory.newErc20Contract.selector,
            address(this),
            ERC20_TOKEN_TYPE,
            token,
            thisChainName,
            name,
            symbol,
            decimals
        );
        uint256 messageId = sendMessage(bridgedLanePosition, remoteMappingTokenFactory, newErc20Contract);
        registerMessages[messageId] = token;
        emit NewErc20TokenRegistered(messageId, token);
    }

    /**
     * @notice lock original token and issuing mapping token from bridged chain
     * @dev maybe some tokens will take some fee when transfer
     * @param bridgedLanePosition the bridged lane positon, this issuing message will be delived to this lane position
     * @param token the original token address
     * @param recipient the recipient who will receive the issued mapping token
     * @param amount amount of the locked token
     */
    function lockAndRemoteIssuing(
        uint32 bridgedLanePosition,
        address token,
        address recipient,
        uint256 amount
    ) external payable whenNotPaused {
        require(registeredTokens[token], "Backing:the token is not registed");

        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Backing:transfer tokens failed");
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        require(balanceBefore.add(amount) == balanceAfter, "Backing:Transfer amount is invalid");
        bytes memory issueMappingToken = abi.encodeWithSelector(
            IMappingTokenFactory.issueMappingToken.selector,
            address(this),
            token,
            recipient,
            amount
        );
        uint256 messageId = sendMessage(bridgedLanePosition, remoteMappingTokenFactory, issueMappingToken);
        lockMessages[messageId] = LockedInfo(token, msg.sender, amount);
        emit TokenLocked(messageId, token, recipient, amount);
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
                IERC20(lockedInfo.token).transfer(lockedInfo.sender, lockedInfo.amount);
            }
            emit TokenLockFinished(messageId, result);
            return;
        }
        address registerToken = registerMessages[messageId];
        // it is register message, if result is true, need to save the token
        if (registerToken != address(0)) {
            delete registerMessages[messageId];
            if (result) {
                registeredTokens[registerToken] = true;
            }
            emit TokenRegisterFinished(messageId, result);
        }
    }

    /**
     * @notice this will be called by inboundLane when the remote mapping token burned and want to unlock the original token
     * @param token the original token address
     * @param recipient the recipient who will receive the unlocked token
     * @param amount amount of the unlocked token
     */
    function unlockFromRemote(
        address mappingTokenFactory,
        address token,
        address recipient,
        uint256 amount
    ) public onlyInBoundLane(mappingTokenFactory) whenNotPaused {
        expendDailyLimit(token, amount);
        if (guard != address(0)) {
            require(IERC20(token).approve(guard, amount), "Backing:approve token transfer to guard failed");
            IInboundLane.InboundLaneNonce memory inboundLaneNonce = IInboundLane(msg.sender).inboundLaneNonce();
            // todo we should transform this messageId to bridged outboundLane messageId
            uint256 messageId = IInboundLane(msg.sender).encodeMessageKey(inboundLaneNonce.last_delivered_nonce);
            IGuard(guard).deposit(messageId, token, recipient, amount);
        } else {
            require(IERC20(token).transfer(recipient, amount), "Backing:unlock transfer failed");
        }
        emit TokenUnlocked(token, recipient, amount);
    }
}
 
