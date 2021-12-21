// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/proxy/utils/Initializable.sol";
import "@zeppelin-solidity-4.4.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@darwinia/contracts-bridge/contracts/interfaces/ICrossChainFilter.sol";
import "@darwinia/contracts-bridge/contracts/interfaces/IOutboundLane.sol";
import "@darwinia/contracts-bridge/contracts/interfaces/IFeeMarket.sol";
import "@darwinia/contracts-utils/contracts/DailyLimit.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "@darwinia/contracts-utils/contracts/Pausable.sol";
import "../interfaces/IBacking.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IMessageVerifier.sol";
import "../interfaces/IMappingTokenFactory.sol";

contract Backing is Initializable, Ownable, DailyLimit, ICrossChainFilter, IBacking, Pausable {
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
    event NewErc20TokenRegistered(uint256 messageId, uint32 bridgedLanePosition, address token);
    event TokenLocked(uint256 messageId, uint64 nonce, uint32 bridgedLanePosition, address token, address recipient, uint256 amount);
    event TokenLockFinished(uint256 messageId, uint64 nonce, bool result);
    event TokenRegisterFinished(uint256 messageId, uint64 nonce, bool result);
    event TokenUnlocked(uint32 bridgedLanePosition, address token, address recipient, uint256 amount);

    modifier onlyInBoundLane(uint32 bridgedChainPosition, uint32 bridgedLanePosition, address mappingTokenFactoryAddress) {
        require(remoteChainPosition == bridgedChainPosition, "Invalid bridged chain position");
        require(remoteMappingTokenFactory == mappingTokenFactoryAddress, "MappingTokenFactory: remote caller is not issuing account");
        require(inboundLanes[bridgedLanePosition] == msg.sender, "MappingTokenFactory: caller is not the inboundLane account");
        _;
    }

    modifier onlyOutBoundLane() {
        uint32 bridgedChainPosition = IMessageVerifier(msg.sender).bridgedChainPosition();
        require(remoteChainPosition == bridgedChainPosition, "Invalid bridged chain position");
        uint32 bridgedLanePosition = IMessageVerifier(msg.sender).bridgedLanePosition();
        require(outboundLanes[bridgedLanePosition] == msg.sender, "caller is not the outboundLane account");
        _;
    }

    function initialize(string memory _chainName, uint32 _bridgedChainPosition, address _remoteMappingTokenFactory, address _feeMarket) public initializer {
        thisChainName = _chainName;
        feeMarket = _feeMarket;
        remoteChainPosition = _bridgedChainPosition;
        remoteMappingTokenFactory = _remoteMappingTokenFactory;
        ownableConstructor();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function setDailyLimit(address mappingToken, uint amount) public onlyOwner  {
        _setDailyLimit(mappingToken, amount);
    }

    function changeDailyLimit(address mappingToken, uint amount) public onlyOwner  {
        _changeDailyLimit(mappingToken, amount);
    }

    function updateFeeMarket(address newFeeMarket) external onlyOwner {
        feeMarket = newFeeMarket;
    }

    // 32 bytes
    // [0, 16)  bytes: Reserved
    // [16, 20) bytes: BridgedChainPosition
    // [20, 24) bytes: BridgedLanePosition
    // [24, 32) bytes: Nonce
    function encodeMessageId(uint32 bridgedLanePosition, uint64 nonce) public view returns (uint256) {
        return uint256(remoteChainPosition) << 96 + uint256(bridgedLanePosition) << 64 + uint256(nonce);
    }

    // here add InBoundLane, and remote issuing module must add the corresponding OutBoundLane
    function addInboundLane(address mappingTokenFactory, address inboundLane) external onlyOwner {
        uint32 bridgedChainPosition = IMessageVerifier(inboundLane).bridgedChainPosition();
        require(remoteChainPosition == bridgedChainPosition, "Invalid bridged chain position");
        uint32 bridgedLanePosition = IMessageVerifier(inboundLane).bridgedLanePosition();
        inboundLanes[bridgedLanePosition] = inboundLane;
        emit NewInBoundLaneAdded(mappingTokenFactory, inboundLane);
    }

    // here add OutBoundLane, and remote issuing module must add the corresponding InBoundLane
    function addOutboundLane(address outboundLane) external onlyOwner {
        uint32 bridgedChainPosition = IMessageVerifier(outboundLane).bridgedChainPosition();
        require(remoteChainPosition == bridgedChainPosition, "Invalid bridged chain position");
        uint32 bridgedLanePosition = IMessageVerifier(outboundLane).bridgedLanePosition();
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
    ) external payable onlyOwner {
        require(registeredTokens[token] == false, "Backing: token has been registered");

        address outboundLane = outboundLanes[bridgedLanePosition];
        require(outboundLane != address(0), "cannot find outboundLane to send message");
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
        require(msg.value >= fee, "not enough fee to pay");
        uint64 nonce = IOutboundLane(outboundLane).send_message{value: fee}(remoteMappingTokenFactory, newErc20Contract);
        uint256 messageId = encodeMessageId(bridgedLanePosition, nonce);
        registerMessages[messageId] = token;
        if (msg.value > fee) {
            require(payable(msg.sender).send(msg.value - fee), "transfer back fee failed");
        }
        emit NewErc20TokenRegistered(messageId, bridgedLanePosition, token);
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
        require(registeredTokens[token], "Backing: the token is not registed");

        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "transfer tokens failed");
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        uint256 newAmount = balanceAfter - balanceBefore;
        address outboundLane = outboundLanes[bridgedLanePosition];
        require(outboundLane != address(0), "Backing: outboundLane not exist");
        bytes memory issueMappingToken = abi.encodeWithSelector(
            IMappingTokenFactory.issueMappingToken.selector,
            address(this),
            token,
            recipient,
            newAmount
        );
        uint256 fee = IFeeMarket(feeMarket).market_fee();
        require(msg.value >= fee, "not enough fee to pay");
        uint64 nonce = IOutboundLane(outboundLane).send_message{value: fee}(remoteMappingTokenFactory, issueMappingToken);
        uint256 messageId = encodeMessageId(bridgedLanePosition, nonce);
        lockMessages[messageId] = LockedInfo(token, msg.sender, amount);
        if (msg.value > fee) {
            require(payable(msg.sender).send(msg.value - fee), "transfer back fee failed");
        }
        emit TokenLocked(messageId, nonce, bridgedLanePosition, token, recipient, newAmount);
    }

    /**
     * @notice this will be called by outboundLane when the register/lock message confirmed
     * @param nonce message nonce to identify the register/lock message
     * @param result the result of the remote call
     */
    function on_messages_delivered(
        uint64 nonce,
        bool result
    ) external onlyOutBoundLane {
        uint32 bridgedLanePosition = IMessageVerifier(msg.sender).bridgedLanePosition();
        uint256 messageId = encodeMessageId(bridgedLanePosition, nonce);
        LockedInfo memory lockedInfo = lockMessages[messageId];
        // it is lock message, if result is false, need to transfer back to the user, otherwise will be locked here
        if (lockedInfo.token != address(0)) {
            delete lockMessages[messageId];
            if (!result) {
                IERC20(lockedInfo.token).transfer(lockedInfo.sender, lockedInfo.amount);
            }
            emit TokenLockFinished(messageId, nonce, result);
            return;
        }
        address registerToken = registerMessages[messageId];
        // it is register message, if result is true, need to save the token
        if (registerToken != address(0)) {
            delete registerMessages[messageId];
            if (result) {
                registeredTokens[registerToken] = true;
            }
            emit TokenRegisterFinished(messageId, nonce, result);
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
     * @param bridgedChainPosition the bridged chain position
     * @param bridgedLanePosition the bridged lane positon
     * @param token the original token address
     * @param recipient the recipient who will receive the unlocked token
     * @param amount amount of the unlocked token
     */
    function unlockFromRemote(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address mappingTokenFactory,
        address token,
        address recipient,
        uint256 amount
    ) public onlyInBoundLane(bridgedChainPosition, bridgedLanePosition, mappingTokenFactory) whenNotPaused {
        expendDailyLimit(token, amount);
        require(IERC20(token).transfer(recipient, amount), "Backing: unlock transfer failed");
        emit TokenUnlocked(bridgedLanePosition, token, recipient, amount);
    }
}
 
