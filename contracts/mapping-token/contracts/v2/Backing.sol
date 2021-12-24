// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/proxy/utils/Initializable.sol";
import "@zeppelin-solidity-4.4.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@zeppelin-solidity-4.4.0/contracts/utils/math/SafeMath.sol";
import "@darwinia/contracts-bridge/contracts/interfaces/ICrossChainFilter.sol";
import "@darwinia/contracts-bridge/contracts/interfaces/IFeeMarket.sol";
import "@darwinia/contracts-bridge/contracts/interfaces/IMessageCommitment.sol";
import "@darwinia/contracts-bridge/contracts/interfaces/IOutboundLane.sol";
import "@darwinia/contracts-utils/contracts/DailyLimit.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "@darwinia/contracts-utils/contracts/Pausable.sol";
import "../interfaces/IBacking.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IMappingTokenFactory.sol";

contract Backing is Initializable, Ownable, DailyLimit, ICrossChainFilter, IBacking, Pausable {
    using SafeMath for uint256;

    struct LockedInfo {
        address token;
        address sender;
        uint256 amount;
    }
    struct InBoundLaneInfo {
        address remoteSender;
        address inBoundLaneAddress;
    }
    uint32 public constant NATIVE_TOKEN_TYPE = 0;
    uint32 public constant ERC20_TOKEN_TYPE = 1;
    address public feeMarket;
    string public thisChainName;
    uint32 public remoteChainPosition;
    address public remoteMappingTokenFactory;
    address public operator;

    // bridge channel
    // bridgedLanePosition => inBoundLaneAddress
    mapping(uint32 => address) public inboundLanes;
    // bridgedLanePosition => outBoundLaneAddress
    mapping(uint32 => address) public outboundLanes;

    // tokenAddress => reistered
    mapping(address => bool) public registeredTokens;

    // (messageId => tokenAddress)
    mapping(uint256 => address) public registerMessages;
    // (messageId => lockedInfo)
    mapping(uint256 => LockedInfo) public lockMessages;

    event NewInBoundLaneAdded(address backingAddress, address inboundLane);
    event NewOutBoundLaneAdded(uint32 bridgedLanePosition, address outboundLane);
    event NewErc20TokenRegistered(uint256 messageId, address token);
    event TokenLocked(uint256 messageId, address token, address recipient, uint256 amount);
    event TokenLockFinished(uint256 messageId, bool result);
    event TokenRegisterFinished(uint256 messageId, bool result);
    event TokenUnlocked(address token, address recipient, uint256 amount);

    modifier onlyInBoundLane(address mappingTokenFactoryAddress) {
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(msg.sender).getLaneInfo();
        require(remoteChainPosition == bridgedChainPosition, "Backing:Invalid bridged chain position");
        require(remoteMappingTokenFactory == mappingTokenFactoryAddress, "Backing:remote caller is not issuing account");
        require(inboundLanes[bridgedLanePosition] == msg.sender, "Backing:caller is not the inboundLane account");
        _;
    }

    modifier onlyOutBoundLane() {
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(msg.sender).getLaneInfo();
        require(remoteChainPosition == bridgedChainPosition, "Backing:Invalid bridged chain position");
        require(outboundLanes[bridgedLanePosition] == msg.sender, "Backing:caller is not the outboundLane account");
        _;
    }

    modifier onlyOperatorOrOwner() {
        require(operator == msg.sender || owner() == msg.sender, "Backing:caller is not the owner or operator");
        _;
    }

    function updateOperator(address _operator) external onlyOperatorOrOwner {
        operator = _operator;
    }

    function initialize(uint32 _bridgedChainPosition, address _remoteMappingTokenFactory, address _feeMarket, string memory _chainName) public initializer {
        feeMarket = _feeMarket;
        remoteChainPosition = _bridgedChainPosition;
        remoteMappingTokenFactory = _remoteMappingTokenFactory;
        thisChainName = _chainName;
        operator = msg.sender;
        ownableConstructor();
    }

    function unpause() external onlyOperatorOrOwner {
        _unpause();
    }

    function pause() external onlyOperatorOrOwner {
        _pause();
    }

    function changeDailyLimit(address mappingToken, uint amount) public onlyOwner  {
        _changeDailyLimit(mappingToken, amount);
    }

    function updateFeeMarket(address newFeeMarket) external onlyOperatorOrOwner {
        feeMarket = newFeeMarket;
    }

    // here add InBoundLane, and remote issuing module must add the corresponding OutBoundLane
    function addInboundLane(address mappingTokenFactory, address inboundLane) external onlyOwner {
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(inboundLane).getLaneInfo();
        require(remoteChainPosition == bridgedChainPosition, "Backing:Invalid bridged chain position");
        inboundLanes[bridgedLanePosition] = inboundLane;
        emit NewInBoundLaneAdded(mappingTokenFactory, inboundLane);
    }

    // here add OutBoundLane, and remote issuing module must add the corresponding InBoundLane
    function addOutboundLane(address outboundLane) external onlyOwner {
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(outboundLane).getLaneInfo();
        require(remoteChainPosition == bridgedChainPosition, "Backing:Invalid bridged chain position");
        outboundLanes[bridgedLanePosition] = outboundLane;
        emit NewOutBoundLaneAdded(bridgedLanePosition, outboundLane);
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

        address outboundLane = outboundLanes[bridgedLanePosition];
        require(outboundLane != address(0), "Backing:cannot find outboundLane to send message");
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
        uint256 fee = IFeeMarket(feeMarket).market_fee();
        require(msg.value >= fee, "Backing:not enough fee to pay");
        uint256 messageId = IOutboundLane(outboundLane).send_message{value: fee}(remoteMappingTokenFactory, newErc20Contract);
        registerMessages[messageId] = token;
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value.sub(fee));
        }
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
        address outboundLane = outboundLanes[bridgedLanePosition];
        require(outboundLane != address(0), "Backing:outboundLane not exist");
        bytes memory issueMappingToken = abi.encodeWithSelector(
            IMappingTokenFactory.issueMappingToken.selector,
            address(this),
            token,
            recipient,
            amount
        );
        uint256 fee = IFeeMarket(feeMarket).market_fee();
        require(msg.value >= fee, "Backing:not enough fee to pay");
        uint256 messageId = IOutboundLane(outboundLane).send_message{value: fee}(remoteMappingTokenFactory, issueMappingToken);
        lockMessages[messageId] = LockedInfo(token, msg.sender, amount);
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value.sub(fee));
        }
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

    function crossChainFilter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address sourceAccount,
        bytes calldata
    ) external view returns (bool) {
        return remoteChainPosition == bridgedChainPosition && inboundLanes[bridgedLanePosition] == msg.sender && remoteMappingTokenFactory == sourceAccount;
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
        require(IERC20(token).transfer(recipient, amount), "Backing:unlock transfer failed");
        emit TokenUnlocked(token, recipient, amount);
    }
}
 
