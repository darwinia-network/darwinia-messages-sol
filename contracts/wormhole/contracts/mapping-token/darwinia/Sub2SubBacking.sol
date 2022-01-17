// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@zeppelin-solidity-4.4.0/contracts/proxy/utils/Initializable.sol";
import "@zeppelin-solidity-4.4.0/contracts/utils/math/SafeMath.sol";
import "../../utils/DailyLimit.sol";
import "../../utils/Ownable.sol";
import "../../utils/Pausable.sol";
import "../../precompile/sub2sub.sol";
import "../interfaces/IERC20.sol";
import "./MappingTokenAddress.sol";

contract Sub2SubBacking is Initializable, Ownable, DailyLimit, Pausable, MappingTokenAddress {
    using SafeMath for uint256;
    struct LockedInfo {
        address token;
        address sender;
        uint256 amount;
    }
    uint32 public constant NATIVE_TOKEN_TYPE = 0;
    uint32 public constant ERC20_TOKEN_TYPE = 1;
    address public operator;

    // this can decide an unique remote chain
    uint32 public messagePalletIndex;

    // token => IsRegistered
    mapping(address => bool) public registeredTokens;

    // (messageId => tokenAddress)
    mapping(bytes => address) public registerMessages;
    // (messageId => lockedInfo)
    mapping(bytes => LockedInfo) public lockMessages;

    event NewErc20TokenRegistered(bytes4 laneId, uint64 nonce, address token);
    event TokenLocked(bytes4 laneId, uint64 nonce, address token, address recipient, uint256 amount);
    event TokenLockFinished(bytes4 laneId, uint64 nonce, bool result);
    event TokenRegisterFinished(bytes4 laneId, uint64 nonce, bool result);
    event TokenUnlocked(address token, address recipient, uint256 amount);

    modifier onlyOperatorOrOwner() {
        require(operator == msg.sender || owner() == msg.sender, "Backing:caller is not the owner or operator");
        _;
    }

    modifier onlySystem() {
        require(SYSTEM_ACCOUNT == msg.sender, "System: caller is not the system account");
        _;
    }

    function initialize() public initializer {
        operator = msg.sender;
        ownableConstructor();
    }

    function setMessagePalletIndex(uint32 index) external onlyOwner {
        messagePalletIndex = index;
    }

    function changeDailyLimit(address token, uint amount) public onlyOwner  {
        _changeDailyLimit(token, amount);
    }

    function unpause() external onlyOperatorOrOwner {
        _unpause();
    }

    function pause() external onlyOperatorOrOwner {
        _pause();
    }

    function updateOperator(address _operator) external onlyOperatorOrOwner {
        operator = _operator;
    }

    function decimalConversion(uint256 balance) internal pure returns (uint256) {
        return balance/(10**9);
    }

    /**
     * @notice reigister new erc20 token to the bridge. Only owner or operator can do this.
     * @param specVersion the spec_version of the bridged chain
     * @param weight the remote dispatch call's weight
     * @param laneId the laneId of the message channel
     * @param token the original token address
     * @param name the name of the original token
     * @param symbol the symbol of the original token
     * @param decimals the decimals of the original token
     */
    function registerErc20Token(
        uint32 specVersion,
        uint64 weight,
        bytes4 laneId,
        address token,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external payable onlyOperatorOrOwner {
        require(registeredTokens[token] == false, "Backing:token has been registered");

        // encode remote register dispatch call
        bytes memory registerErc20 = SubToSubBridge(DISPATCH_ENCODER).encode_register_from_remote_dispatch_call(
            specVersion,
            weight,
            ERC20_TOKEN_TYPE,
            token,
            name,
            symbol,
            decimals
        );

        // transform fee in contract(decimals is 18) to pallet(decimals is 9)
        uint256 fee = decimalConversion(msg.value);

        // encode 
        // this fee is needed to send to the sub<>sub bridge fund to pay relayer
        bytes memory sendMessageCall = SubToSubBridge(DISPATCH_ENCODER).encode_send_message_dispatch_call(
            messagePalletIndex,
            laneId,
            registerErc20,
            fee);

        // send s2s message
        (bool success, ) = DISPATCH.call(sendMessageCall);
        require(success, "burn: send register message failed");
        uint64 nonce = SubToSubBridge(DISPATCH_ENCODER).outbound_latest_generated_nonce(laneId);
        bytes memory messageId = abi.encode(laneId, nonce);
        registerMessages[messageId] = token;
        emit NewErc20TokenRegistered(laneId, nonce, token);
    }

    /**
     * @notice lock original token and issuing mapping token from bridged chain
     * @param specVersion the spec_version of the bridged chain
     * @param weight the remote dispatch call's weight
     * @param laneId the laneId of the message channel
     * @param token the original token address
     * @param recipient the recipient who will receive the issued mapping token
     * @param amount amount of the locked token
     */
    function lockAndRemoteIssuing(
        uint32 specVersion,
        uint64 weight,
        bytes4 laneId,
        address token,
        address recipient,
        uint256 amount
    ) external payable whenNotPaused {
        require(registeredTokens[token], "Backing:the token is not registed");

        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Backing:transfer tokens failed");
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        require(balanceBefore.add(amount) == balanceAfter, "Backing:Transfer amount is invalid");
        bytes memory issueFromRemote = SubToSubBridge(DISPATCH_ENCODER).encode_issue_from_remote_dispatch_call(
            specVersion,
            weight,
            token,
            recipient,
            amount
        );
        
        uint256 fee = decimalConversion(msg.value);
        bytes memory sendMessageCall = SubToSubBridge(DISPATCH_ENCODER).encode_send_message_dispatch_call(
            messagePalletIndex,
            laneId,
            issueFromRemote,
            fee);

        (bool success, ) = DISPATCH.call(sendMessageCall);
        require(success, "burn: send register message failed");
        uint64 nonce = SubToSubBridge(DISPATCH_ENCODER).outbound_latest_generated_nonce(laneId);
        bytes memory messageId = abi.encode(laneId, nonce);

        lockMessages[messageId] = LockedInfo(token, msg.sender, amount);
        emit TokenLocked(laneId, nonce, token, recipient, amount);
    }

    function confirmRemoteLockOrRegister(bytes4 laneId, uint64 nonce, bool result) external onlySystem {
        bytes memory messageId = abi.encode(laneId, nonce);
        LockedInfo memory lockedInfo = lockMessages[messageId];
        // it is lock message, if result is false, need to transfer back to the user, otherwise will be locked here
        if (lockedInfo.token != address(0)) {
            delete lockMessages[messageId];
            if (!result) {
                IERC20(lockedInfo.token).transfer(lockedInfo.sender, lockedInfo.amount);
            }
            emit TokenLockFinished(laneId, nonce, result);
            return;
        }
        address registerToken = registerMessages[messageId];
        // it is register message, if result is true, need to save the token
        if (registerToken != address(0)) {
            delete registerMessages[messageId];
            if (result) {
                registeredTokens[registerToken] = true;
            }
            emit TokenRegisterFinished(laneId, nonce, result);
        }
    }

    /**
     * @notice this will be called by system when the remote mapping token burned and want to unlock the original token
     * @param token the original token address
     * @param recipient the recipient who will receive the unlocked token
     * @param amount amount of the unlocked token
     */
    function unlockFromRemote(
        address token,
        address recipient,
        uint256 amount
    ) external onlySystem whenNotPaused {
        expendDailyLimit(token, amount);
        require(IERC20(token).transfer(recipient, amount), "Backing:unlock transfer failed");
        emit TokenUnlocked(token, recipient, amount);
    }
}
 
