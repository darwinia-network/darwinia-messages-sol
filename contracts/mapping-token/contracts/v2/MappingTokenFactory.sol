// SPDX-License-Identifier: MIT
// This is the Issuing Module(Mapping-token-factory) of the ethereum like bridge.
// We trust the inboundLane/outboundLane when we add them to the module.
// It means that each message from the inboundLane is verified correct and truthly from the sourceAccount.
// Only we need is to verify the sourceAccount is expected. And we add it to the Filter.
pragma solidity ^0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/proxy/utils/Initializable.sol";
import "@zeppelin-solidity-4.4.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@darwinia/contracts-bridge/contracts/interfaces/ICrossChainFilter.sol";
import "@darwinia/contracts-bridge/contracts/interfaces/IFeeMarket.sol";
import "@darwinia/contracts-bridge/contracts/interfaces/IMessageCommitment.sol";
import "@darwinia/contracts-bridge/contracts/interfaces/IOutboundLane.sol";
import "@darwinia/contracts-utils/contracts/DailyLimit.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "@darwinia/contracts-utils/contracts/Pausable.sol";
import "../interfaces/IBacking.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IGuard.sol";
import "../interfaces/IInboundLane.sol";
import "../interfaces/IMappingTokenFactory.sol";

contract MappingTokenFactory is Initializable, Ownable, DailyLimit, ICrossChainFilter, IMappingTokenFactory, Pausable {
    address public constant BLACK_HOLE_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    struct OriginalInfo {
        uint32  bridgedChainPosition;
        // 0 - NativeToken
        // 1 - Erc20Token
        // ...
        uint32  tokenType;
        address backingAddress;
        address originalToken;
    }
    struct UnconfirmedInfo {
        address sender;
        address mappingToken;
        uint256 amount;
    }
    struct InBoundLaneInfo {
        address remoteSender;
        address inBoundLaneAddress;
    }
    address public operator;
    // fee market
    address public feeMarket;
    // guard
    address public guard;
    // the mapping token list
    address[] public allMappingTokens;
    // salt=>mappingToken, the salt is derived from origin token on backing chain
    // so this is a mapping from origin to mapping token
    mapping(bytes32 => address) public salt2MappingToken;
    // mappingToken=>info the info is the original token info
    // so this is a mapping from mappingToken to original token
    mapping(address => OriginalInfo) public mappingToken2OriginalInfo;
    // tokenType=>Logic
    // tokenType comes from original token, the logic contract is used to create the mapping-token contract
    mapping(uint32 => address) public tokenType2Logic;

    // bridge channel
    mapping(uint256 => InBoundLaneInfo) public inboundLanes;
    mapping(uint256 => address) public outboundLanes;

    mapping(uint256 => UnconfirmedInfo) public unlockRemoteUnconfirmed;

    event NewLogicSetted(uint32 tokenType, address addr);
    event IssuingERC20Created(address backingAddress, address originalToken, address mappingToken);
    event MappingTokenUpdated(bytes32 salt, address oldAddress, address newAddress);
    event NewInBoundLaneAdded(address backing, address inboundLane);
    event NewOutBoundLaneAdded(address outboundLane);
    event BurnAndWaitingConfirm(uint256 messageId, address sender, address recipient, address token, uint256 amount);
    event RemoteUnlockConfirmed(uint256 messageId, bool result);

    receive() external payable {
    }

    function initialize(address _feeMarket) public initializer {
        feeMarket = _feeMarket;
        operator = msg.sender;
        ownableConstructor();
    }

    function unpause() external onlyOperatorOrOwner {
        _unpause();
    }

    function pause() external onlyOperatorOrOwner {
        _pause();
    }

    function updateFeeMarket(address newFeeMarket) external onlyOwner {
        feeMarket = newFeeMarket;
    }

    function updateGuard(address newGuard) external onlyOwner {
        guard = newGuard;
    }

    /**
     * @dev Throws if called by any account other than the inboundlane account.
     */
    modifier onlyInBoundLane(address backingAddress) {
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(msg.sender).getLaneInfo();
        uint256 remoteId = encodeBridgedBackingId(
            bridgedChainPosition,
            bridgedLanePosition,
            backingAddress);
        require(inboundLanes[remoteId].inBoundLaneAddress == msg.sender, "MappingTokenFactory:caller is not the inboundLane account");
        require(inboundLanes[remoteId].remoteSender == backingAddress, "MappingTokenFactory:remote caller is not the backing account");
        _;
    }

    /**
     * @dev Throws if called by any account other than the outboundlane account.
     */
    modifier onlyOutBoundLane() {
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(msg.sender).getLaneInfo();
        uint256 outBoundId = encodeBridgedBoundId(bridgedChainPosition, bridgedLanePosition);
        require(outboundLanes[outBoundId] == msg.sender, "MappingTokenFactory:caller is not the outboundLane account");
        _;
    }

    modifier onlyOperatorOrOwner() {
        require(operator == msg.sender || owner() == msg.sender, "MappingTokenFactory:caller is not the owner or operator");
        _;
    }

    function updateOperator(address _operator) external onlyOperatorOrOwner {
        operator = _operator;
    }

    // 32 bytes
    // [0, 24)  bytes: Reserved
    // [24, 28) bytes: BridgedChainPosition
    // [28, 32) bytes: BridgedLanePosition
    function encodeBridgedBoundId(uint32 bridgedChainPosition, uint32 bridgedLanePosition) public pure returns (uint256) {
        return uint256(bridgedChainPosition) << 32 + uint256(bridgedLanePosition);
    }

    // 32 bytes
    // [0, 4)   bytes: Reserved
    // [4, 12)  bytes: BridgedBoundId
    // [12, 32) bytes: BackingAddress
    function encodeBridgedBackingId(uint32 bridgedChainPosition, uint32 bridgedLanePosition, address backingAddress) public pure returns (uint256) {
        return encodeBridgedBoundId(bridgedChainPosition, bridgedLanePosition) << 160 + uint256(uint160(backingAddress));
    }

    /**
     * @notice add new inboundLane to mapping-token-factory, remote backing module must add the corresponding OutBoundLane
     * @param backingAddress the remote backingAddress
     * @param inboundLane the inboundLane address
     */
    function addInboundLane(address backingAddress, address inboundLane) external onlyOwner {
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(inboundLane).getLaneInfo();
        uint256 remoteId = encodeBridgedBackingId(bridgedChainPosition, bridgedLanePosition, backingAddress);
        inboundLanes[remoteId] = InBoundLaneInfo(backingAddress, inboundLane);
        emit NewInBoundLaneAdded(backingAddress, inboundLane);
    }

    /**
     * @notice add new outboundLane to mapping-token-factory, remote backing module must add the corresponding InBoundLane
     * @param outboundLane the outboundLane address
     */
    function addOutBoundLane(address outboundLane) external onlyOwner {
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(outboundLane).getLaneInfo();
        uint256 outBoundId = encodeBridgedBoundId(bridgedChainPosition, bridgedLanePosition);
        outboundLanes[outBoundId] = outboundLane;
        emit NewOutBoundLaneAdded(outboundLane);
    }

    function changeDailyLimit(address mappingToken, uint amount) public onlyOwner  {
        _changeDailyLimit(mappingToken, amount);
    }

    function setTokenContractLogic(uint32 tokenType, address logic) external onlyOwner {
        tokenType2Logic[tokenType] = logic;
        emit NewLogicSetted(tokenType, logic);
    }

    function transferMappingTokenOwnership(address mappingToken, address new_owner) external onlyOwner {
        Ownable(mappingToken).transferOwnership(new_owner);
    }

    /**
     * @notice add mapping-token address by owner
     * @param bridgedChainPosition the bridged chain position
     * @param backingAddress the remote backingAddress
     * @param originalToken the original token address
     * @param mappingToken the mapping token address
     * @param tokenType the token type of the original token
     */
    function addMappingToken(
        uint32 bridgedChainPosition,
        address backingAddress,
        address originalToken,
        address mappingToken,
        uint32 tokenType
    ) external onlyOwner {
        bytes32 salt = keccak256(abi.encodePacked(bridgedChainPosition, backingAddress, originalToken));
        address existed = salt2MappingToken[salt];
        require(existed == address(0), "the mapping token exist");
        allMappingTokens.push(mappingToken);
        mappingToken2OriginalInfo[mappingToken] = OriginalInfo(bridgedChainPosition, tokenType, backingAddress, originalToken);
        salt2MappingToken[salt] = mappingToken;
        emit MappingTokenUpdated(salt, existed, mappingToken);
    }

    // internal
    function deploy(bytes32 salt, uint32 tokenType) internal returns (address addr) {
        bytes memory bytecode = type(TransparentUpgradeableProxy).creationCode;
        bytes memory bytecodeWithInitdata = abi.encodePacked(bytecode, abi.encode(tokenType2Logic[tokenType], address(BLACK_HOLE_ADDRESS), ""));

        assembly {
            addr := create2(0, add(bytecodeWithInitdata, 0x20), mload(bytecodeWithInitdata), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    function tokenLength() public view returns (uint) {
        return allMappingTokens.length;
    }

    function getMappingToken(uint32 bridgedChainPosition, address backingAddress, address originalToken) public view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(bridgedChainPosition, backingAddress, originalToken));
        return salt2MappingToken[salt];
    }

    /**
     * @notice filter the untrusted remote sourceAccount, this will called by inboundLane
     * @param bridgedChainPosition the bridged chain position
     * @param bridgedLanePosition the bridged lane position
     * @param backingAddress the backingAddress which send this message
     */
    function crossChainFilter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address backingAddress,
        bytes calldata
    ) external view returns (bool) {
        uint256 remoteId = encodeBridgedBackingId(bridgedChainPosition, bridgedLanePosition, backingAddress);
        return inboundLanes[remoteId].inBoundLaneAddress == msg.sender && inboundLanes[remoteId].remoteSender == backingAddress;
    }

    /**
     * @notice create new erc20 mapping contract, this can only be called by inboundLane
     * @param backingAddress the backingAddress which send this message
     * @param tokenType the original token type
     * @param originalToken the original token address
     * @param name the name of the original erc20 token
     * @param symbol the symbol of the original erc20 token
     * @param decimals the decimals of the original erc20 token
     */
    function newErc20Contract(
        address backingAddress,
        uint32 tokenType,
        address originalToken,
        string memory bridgedChainName,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public onlyInBoundLane(backingAddress) whenNotPaused returns (address mappingToken) {
        require(tokenType == 0 || tokenType == 1, "MappingTokenFactory:token type cannot mapping to erc20 token");
        // (bridgeChainId, backingAddress, originalToken) pack a unique new contract salt
        uint32 bridgedChainPosition = IMessageCommitment(msg.sender).bridgedChainPosition();
        bytes32 salt = keccak256(abi.encodePacked(bridgedChainPosition, backingAddress, originalToken));
        require(salt2MappingToken[salt] == address(0), "MappingTokenFactory:contract has been deployed");
        mappingToken = deploy(salt, tokenType);
        IMappingToken(mappingToken).initialize(
            string(abi.encodePacked(name, "[", bridgedChainName, ">")),
            string(abi.encodePacked("x", symbol)),
            decimals);

        // save the mapping tokens in an array so it can be listed
        allMappingTokens.push(mappingToken);
        // map the originToken to mappingInfo
        salt2MappingToken[salt] = mappingToken;
        // map the mappingToken to origin info
        mappingToken2OriginalInfo[mappingToken] = OriginalInfo(bridgedChainPosition, tokenType, backingAddress, originalToken);
        emit IssuingERC20Created(backingAddress, originalToken, mappingToken);
    }

    /**
     * @notice issue mapping token, only can be called by inboundLane
     * @param backingAddress the backingAddress which send this message
     * @param originalToken the original token address
     * @param recipient the recipient of the issued mapping token
     * @param amount the amount of the issued mapping token
     */
    function issueMappingToken(
        address backingAddress,
        address originalToken,
        address recipient,
        uint256 amount
    ) public onlyInBoundLane(backingAddress) whenNotPaused {
        uint32 bridgedChainPosition = IMessageCommitment(msg.sender).bridgedChainPosition();
        address mappingToken = getMappingToken(bridgedChainPosition, backingAddress, originalToken);
        require(mappingToken != address(0), "MappingTokenFactory:mapping token has not created");
        require(amount > 0, "MappingTokenFactory:can not receive amount zero");
        expendDailyLimit(mappingToken, amount);
        if (guard != address(0)) {
            IERC20(mappingToken).mint(address(this), amount);
            require(IERC20(mappingToken).approve(guard, amount), "MappingTokenFactory:approve token transfer to guard failed");
            IInboundLane.InboundLaneNonce memory inboundLaneNonce = IInboundLane(msg.sender).inboundLaneNonce();
            // todo we should transform this messageId to bridged outboundLane messageId
            uint256 messageId = IInboundLane(msg.sender).encodeMessageKey(inboundLaneNonce.last_delivered_nonce);
            IGuard(guard).deposit(messageId, mappingToken, recipient, amount);
        } else {
            IERC20(mappingToken).mint(recipient, amount);
        }
    }

    /**
     * @notice burn mapping token and unlock remote original token, waiting for the confirm
     * @param bridgedLanePosition the bridged lane position to send the unlock message
     * @param mappingToken the burt mapping token address
     * @param recipient the recipient of the remote unlocked token
     * @param amount the amount of the burn and unlock
     */
    function burnAndRemoteUnlockWaitingConfirm(
        uint32 bridgedLanePosition,
        address mappingToken,
        address recipient,
        uint256 amount
    ) external payable whenNotPaused {
        require(amount > 0, "MappingTokenFactory:can not transfer amount zero");
        OriginalInfo memory info = mappingToken2OriginalInfo[mappingToken];
        require(info.originalToken != address(0), "MappingTokenFactory:token is not created by factory");
        // Lock the fund in this before message on remote backing chain get dispatched successfully and burn finally
        // If remote backing chain unlock the origin token successfully, then this fund will be burned.
        // Otherwise, this fund will be transfered back to the msg.sender.
        require(IERC20(mappingToken).transferFrom(msg.sender, address(this), amount), "MappingTokenFactory:transfer token failed");

        uint256 outBoundId = encodeBridgedBoundId(info.bridgedChainPosition, bridgedLanePosition);
        address outboundLane = outboundLanes[outBoundId];
        require(outboundLane != address(0), "MappingTokenFactory:the outbound lane is not exist");
        bytes memory unlockFromRemote = abi.encodeWithSelector(
            IBacking.unlockFromRemote.selector,
            address(this),
            info.originalToken,
            recipient,
            amount
        );
        uint256 fee = IFeeMarket(feeMarket).market_fee();
        require(msg.value >= fee, "MappingTokenFactory:not enough fee to pay");
        uint256 messageId = IOutboundLane(outboundLane).send_message{value: fee}(info.backingAddress, unlockFromRemote);
        unlockRemoteUnconfirmed[messageId] = UnconfirmedInfo(msg.sender, mappingToken, amount);
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
        emit BurnAndWaitingConfirm(messageId, msg.sender, recipient, mappingToken, amount);
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
        require(info.amount > 0 && info.sender != address(0) && info.mappingToken != address(0), "MappingTokenFactory:invalid unconfirmed message");
        if (result) {
            IERC20(info.mappingToken).burn(address(this), info.amount);
        } else {
            require(IERC20(info.mappingToken).transfer(info.sender, info.amount), "MappingTokenFactory:transfer back failed");
        }
        delete unlockRemoteUnconfirmed[messageId];
        emit RemoteUnlockConfirmed(messageId, result);
    }
}

