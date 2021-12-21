// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/proxy/utils/Initializable.sol";
import "@zeppelin-solidity-4.4.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@darwinia/contracts-bridge/contracts/interfaces/ICrossChainFilter.sol";
import "@darwinia/contracts-bridge/contracts/interfaces/IOutboundLane.sol";
import "@darwinia/contracts-utils/contracts/DailyLimit.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "@darwinia/contracts-utils/contracts/Pausable.sol";
import "../interfaces/IBacking.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IMessageVerifier.sol";
import "../interfaces/IMappingTokenFactory.sol";

contract Backing is Initializable, Ownable, DailyLimit, ICrossChainFilter, IBacking, Pausable {
    struct RegisterInfo {
        address token;
        uint32 bridgedChainPosition;
        address mappingTokenFactory;
    }
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
    string public thisChainName;

    // bridge channel
    mapping(bytes32 => InBoundLaneInfo) public inboundLanes;
    mapping(bytes32 => address) public outboundLanes;

    // tokenAddress => remoteChainId => mappingTokenFactory
    mapping(address => mapping(uint32 => address)) public tokens;

    // (messageId => RegisterInfo)
    mapping(bytes32 => RegisterInfo) public registerMessages;
    // (messageId => lockedInfo)
    mapping(bytes32 => LockedInfo) public lockMessages;

    event NewInBoundLaneAdded(address backingAddress, address inboundLane);
    event NewOutBoundLaneAdded(address outboundLane);
    event NewErc20TokenRegistered(bytes32 messageId, uint32 bridgedChainPosition, uint32 bridgedLanePosition, address mappingTokenFactory, address token);
    event TokenLocked(bytes32 messageId, uint64 nonce, uint32 bridgedChainPosition, uint32 bridgedLanePosition, address token, address recipient, uint256 amount);
    event TokenLockFinished(bytes32 messageId, uint64 nonce, bool result);
    event TokenRegisterFinished(bytes32 messageId, uint64 nonce, bool result);
    event TokenUnlocked(uint32 bridgedChainPosition, uint32 bridgedLanePosition, address mappingTokenFactory, address token, address recipient, uint256 amount);

    modifier onlyInBoundLane(uint32 bridgedChainPosition, uint32 bridgedLanePosition, address mappingTokenFactoryAddress) {
        bytes32 remoteId = keccak256(abi.encodePacked(bridgedChainPosition, bridgedLanePosition, mappingTokenFactoryAddress));
        require(inboundLanes[remoteId].remoteSender == mappingTokenFactoryAddress, "MappingTokenFactory: remote caller is not issuing account");
        require(inboundLanes[remoteId].inBoundLaneAddress == msg.sender, "MappingTokenFactory: caller is not the inboundLane account");
        _;
    }

    modifier onlyOutBoundLane() {
        uint32 bridgedChainPosition = IMessageVerifier(msg.sender).bridgedChainPosition();
        uint32 bridgedLanePosition = IMessageVerifier(msg.sender).bridgedLanePosition();
        bytes32 remoteId = keccak256(abi.encodePacked(bridgedChainPosition, bridgedLanePosition));
        require(outboundLanes[remoteId] == msg.sender, "MappingTokenFactory: caller is not the outboundLane account");
        _;
    }

    function initialize(string memory _chainName) public initializer {
        thisChainName = _chainName;
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

    // here add InBoundLane, and remote issuing module must add the corresponding OutBoundLane
    function addInboundLane(address mappingTokenFactory, address inboundLane) external onlyOwner {
        uint32 bridgedChainPosition = IMessageVerifier(inboundLane).bridgedChainPosition();
        uint32 bridgedLanePosition = IMessageVerifier(inboundLane).bridgedLanePosition();
        bytes32 remoteId = keccak256(abi.encodePacked(bridgedChainPosition, bridgedLanePosition, mappingTokenFactory));
        inboundLanes[remoteId] = InBoundLaneInfo(mappingTokenFactory, inboundLane);
        emit NewInBoundLaneAdded(mappingTokenFactory, inboundLane);
    }

    // here add OutBoundLane, and remote issuing module must add the corresponding InBoundLane
    function addOutboundLane(address outboundLane) external onlyOwner {
        uint32 bridgedChainPosition = IMessageVerifier(outboundLane).bridgedChainPosition();
        uint32 bridgedLanePosition = IMessageVerifier(outboundLane).bridgedLanePosition();
        bytes32 remoteId = keccak256(abi.encodePacked(bridgedChainPosition, bridgedLanePosition));
        outboundLanes[remoteId] = outboundLane;
        emit NewOutBoundLaneAdded(outboundLane);
    }

    /**
     * @notice reigister new erc20 token to the bridge. Only owner can do this.
     * @param bridgedChainPosition the bridged chain position, the mapping token will be created on this target chain
     * @param bridgedLanePosition the bridged lane positon, this register message will be delived to this lane position
     * @param mappingTokenFactory the bridged mappingTokenFactory address who will receive this message
     * @param token the original token address
     * @param name the name of the original token
     * @param symbol the symbol of the original token
     * @param decimals the decimals of the original token
     */
    function registerErc20Token(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address mappingTokenFactory,
        address token,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external payable onlyOwner {
        require(tokens[token][bridgedChainPosition] == address(0), "Backing: token has been registered");

        address outboundLane = getOutBoundLane(bridgedChainPosition, bridgedLanePosition);
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
        uint64 nonce = IOutboundLane(outboundLane).send_message(mappingTokenFactory, newErc20Contract);
        bytes32 messageId = keccak256(abi.encodePacked(outboundLane, nonce));
        registerMessages[messageId] = RegisterInfo(token, bridgedChainPosition, mappingTokenFactory);
        emit NewErc20TokenRegistered(messageId, bridgedChainPosition, bridgedLanePosition, mappingTokenFactory, token);
    }

    /**
     * @notice lock original token and issuing mapping token from bridged chain
     * @dev maybe some tokens will take some fee when transfer
     * @param bridgedChainPosition the bridged chain position, the mapping token will be issued on this target chain
     * @param bridgedLanePosition the bridged lane positon, this issuing message will be delived to this lane position
     * @param token the original token address
     * @param recipient the recipient who will receive the issued mapping token
     * @param amount amount of the locked token
     */
    function lockAndRemoteIssuing(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address token,
        address recipient,
        uint256 amount
    ) external payable whenNotPaused {
        address mappingTokenFactory = tokens[token][bridgedChainPosition];
        require(mappingTokenFactory != address(0), "Backing: the token is not registed");

        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "transfer tokens failed");
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        uint256 newAmount = balanceAfter - balanceBefore;
        address outboundLane = getOutBoundLane(bridgedChainPosition, bridgedLanePosition);
        require(outboundLane != address(0), "Backing: outboundLane not exist");
        bytes memory issueMappingToken = abi.encodeWithSelector(
            IMappingTokenFactory.issueMappingToken.selector,
            address(this),
            token,
            recipient,
            newAmount
        );
        uint64 nonce = IOutboundLane(outboundLane).send_message(mappingTokenFactory, issueMappingToken);
        bytes32 messageId = keccak256(abi.encodePacked(outboundLane, nonce));
        lockMessages[messageId] = LockedInfo(token, msg.sender, amount);
        emit TokenLocked(messageId, nonce, bridgedChainPosition, bridgedLanePosition, token, recipient, newAmount);
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
        address outboundLane = msg.sender;
        bytes32 messageId = keccak256(abi.encodePacked(outboundLane, nonce));
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
        RegisterInfo memory registerInfo = registerMessages[messageId];
        // it is register message, if result is true, need to save the token
        if (registerInfo.token != address(0)) {
            delete registerMessages[messageId];
            if (result) {
                tokens[registerInfo.token][registerInfo.bridgedChainPosition] = registerInfo.mappingTokenFactory;
            }
            emit TokenRegisterFinished(messageId, nonce, result);
        }
    }

    function crossChainFilter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address mappingTokenFactory,
        bytes calldata
    ) external view returns (bool) {
        bytes32 remoteId = keccak256(abi.encodePacked(bridgedChainPosition, bridgedLanePosition, mappingTokenFactory));
        return inboundLanes[remoteId].inBoundLaneAddress == msg.sender && inboundLanes[remoteId].remoteSender == mappingTokenFactory;
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
        emit TokenUnlocked(bridgedChainPosition, bridgedLanePosition, mappingTokenFactory, token, recipient, amount);
    }

    function getOutBoundLane(uint32 bridgedChainPosition, uint32 bridgedLanePosition) public view returns(address) {
        bytes32 remoteId = keccak256(abi.encodePacked(bridgedChainPosition, bridgedLanePosition));
        return outboundLanes[remoteId];
    }
}
 
