// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/utils/math/SafeMath.sol";
import "../Backing.sol";
import "../../interfaces/IBacking.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IGuard.sol";
import "../../interfaces/IHelixMessageHandle.sol";
import "../../interfaces/IHelixMessageHandleSupportingConfirm.sol";
import "../../interfaces/IErc20MappingTokenFactory.sol";
import "../../../utils/DailyLimit.sol";

contract Erc20BackingSupportingConfirm is Backing, DailyLimit, IBacking {
    using SafeMath for uint256;
    struct LockedInfo {
        address token;
        address sender;
        uint256 amount;
    }
    uint32 public constant NATIVE_TOKEN_TYPE = 0;
    uint32 public constant ERC20_TOKEN_TYPE = 1;
    address public guard;
    string public chainName;

    // (messageId => tokenAddress)
    mapping(uint256 => address) public registerMessages;

    // tokenAddress => reistered
    mapping(address => bool) public registeredTokens;

    // (messageId => lockedInfo)
    mapping(uint256 => LockedInfo) public lockMessages;

    event NewErc20TokenRegistered(uint256 messageId, address token);
    event TokenLocked(uint256 messageId, address token, address recipient, uint256 amount);
    event TokenLockFinished(uint256 messageId, bool result);
    event TokenRegisterFinished(uint256 messageId, bool result);
    event TokenUnlocked(address token, address recipient, uint256 amount);

    receive() external payable {
    }

    function setMessageHandle(address _messageHandle) external onlyAdmin {
        _setMessageHandle(_messageHandle);
    }

    function setChainName(string memory _chainName) external onlyAdmin {
        chainName = _chainName;
    }

    function changeDailyLimit(address mappingToken, uint amount) public onlyAdmin  {
        _changeDailyLimit(mappingToken, amount);
    }

    function updateGuard(address newGuard) external onlyAdmin {
        guard = newGuard;
    }

    /**
     * @notice reigister new erc20 token to the bridge. Only owner can do this.
     * @param token the original token address
     * @param name the name of the original token
     * @param symbol the symbol of the original token
     * @param decimals the decimals of the original token
     */
    function registerErc20Token(
        address token,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external payable onlyOperator {
        require(registeredTokens[token] == false, "Backing:token has been registered");

        bytes memory newErc20Contract = abi.encodeWithSelector(
            IErc20MappingTokenFactory.newErc20Contract.selector,
            ERC20_TOKEN_TYPE,
            token,
            chainName,
            name,
            symbol,
            decimals
        );
        uint256 messageId = IHelixMessageHandle(messageHandle).sendMessage{value: msg.value}(remoteMappingTokenFactory, newErc20Contract);
        registerMessages[messageId] = token;
        emit NewErc20TokenRegistered(messageId, token);
    }

    /**
     * @notice lock original token and issuing mapping token from bridged chain
     * @dev maybe some tokens will take some fee when transfer
     * @param token the original token address
     * @param recipient the recipient who will receive the issued mapping token
     * @param amount amount of the locked token
     */
    function lockAndRemoteIssuing(
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
            IErc20MappingTokenFactory.issueMappingToken.selector,
            token,
            recipient,
            amount
        );
        uint256 messageId = IHelixMessageHandle(messageHandle).sendMessage{value: msg.value}(remoteMappingTokenFactory, issueMappingToken);
        lockMessages[messageId] = LockedInfo(token, msg.sender, amount);
        emit TokenLocked(messageId, token, recipient, amount);
    }

    /**
     * @notice this will be called by outboundLane when the register/lock message confirmed
     * @param messageId message id to identify the register/lock message
     * @param result the result of the remote call
     */
    function onMessageDelivered(
        uint256 messageId,
        bool result
    ) external onlyMessageHandle {
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
     * @param mappingTokenFactory the remote mapping token factory address
     * @param token the original token address
     * @param recipient the recipient who will receive the unlocked token
     * @param amount amount of the unlocked token
     */
    function unlockFromRemote(
        address mappingTokenFactory,
        address token,
        address recipient,
        uint256 amount
    ) public onlyMessageHandle whenNotPaused {
        expendDailyLimit(token, amount);
        if (guard != address(0)) {
            require(IERC20(token).approve(guard, amount), "Backing:approve token transfer to guard failed");
            uint256 messageId = IHelixMessageHandleSupportingConfirm(messageHandle).latestRecvMessageId();
            IGuard(guard).deposit(messageId, token, recipient, amount);
        } else {
            require(IERC20(token).transfer(recipient, amount), "Backing:unlock transfer failed");
        }
        emit TokenUnlocked(token, recipient, amount);
    }

    /**
     * @notice this should not be used unless there is a non-recoverable error in the bridge or the target chain
     * we use this to protect user's asset from being locked up
     */
    function rescueFunds(
        address token,
        address recipient,
        uint256 amount
    ) external onlyAdmin {
        IERC20(token).transfer(recipient, amount);
    }
}
 
