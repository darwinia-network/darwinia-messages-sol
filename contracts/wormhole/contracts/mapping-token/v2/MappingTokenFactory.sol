// SPDX-License-Identifier: MIT
// This is the Issuing Module(Mapping-token-factory) of the ethereum like bridge.
// We trust the inboundLane/outboundLane when we add them to the module.
// It means that each message from the inboundLane is verified correct and truthly from the sourceAccount.
// Only we need is to verify the sourceAccount is expected. And we add it to the Filter.
pragma solidity ^0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/proxy/utils/Initializable.sol";
import "../interfaces/ICrossChainFilter.sol";
import "../interfaces/IFeeMarket.sol";
import "../interfaces/IMessageCommitment.sol";
import "../interfaces/IOutboundLane.sol";
import "../../utils/Ownable.sol";
import "../../utils/Pausable.sol";
import "../interfaces/IInboundLane.sol";

contract MappingTokenFactory is Initializable, Ownable, ICrossChainFilter, Pausable {
    struct OriginalInfo {
        uint32  bridgedChainPosition;
        address backingAddress;
        address originalToken;
    }
    struct InBoundLaneInfo {
        address remoteSender;
        address inBoundLaneAddress;
    }
    address public operator;
    // fee market
    address public feeMarket;
    // the mapping token list
    address[] public allMappingTokens;
    // salt=>mappingToken, the salt is derived from origin token on backing chain
    // so this is a mapping from origin to mapping token
    mapping(bytes32 => address) public salt2MappingToken;
    // mappingToken=>info the info is the original token info
    // so this is a mapping from mappingToken to original token
    mapping(address => OriginalInfo) public mappingToken2OriginalInfo;

    // bridge channel
    mapping(uint256 => InBoundLaneInfo) public inboundLanes;
    mapping(uint256 => address) public outboundLanes;

    event MappingTokenUpdated(bytes32 salt, address oldAddress, address newAddress);
    event NewInBoundLaneAdded(address backing, address inboundLane);
    event NewOutBoundLaneAdded(address outboundLane);

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

    function transferMappingTokenOwnership(address mappingToken, address new_owner) external onlyOwner {
        Ownable(mappingToken).transferOwnership(new_owner);
    }

    /**
     * @notice add mapping-token address by owner
     * @param bridgedChainPosition the bridged chain position
     * @param backingAddress the remote backingAddress
     * @param originalToken the original token address
     * @param mappingToken the mapping token address
     */
    function addMappingToken(
        uint32 bridgedChainPosition,
        address backingAddress,
        address originalToken,
        address mappingToken
    ) external onlyOwner {
        bytes32 salt = keccak256(abi.encodePacked(bridgedChainPosition, backingAddress, originalToken));
        address existed = salt2MappingToken[salt];
        require(existed == address(0), "the mapping token exist");

        // save the mapping tokens in an array so it can be listed
        allMappingTokens.push(mappingToken);
        // map the originToken to mappingInfo
        salt2MappingToken[salt] = mappingToken;
        // map the mappingToken to origin info
        mappingToken2OriginalInfo[mappingToken] = OriginalInfo(bridgedChainPosition, backingAddress, originalToken);
        emit MappingTokenUpdated(salt, existed, mappingToken);
    }

    // internal
    function deploy(bytes32 salt, bytes memory bytecodeWithInitdata) internal returns (address addr) {
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

    function _sendMessage(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address receiver,
        bytes memory message
    ) internal returns(uint256) {
        uint256 outBoundId = encodeBridgedBoundId(bridgedChainPosition, bridgedLanePosition);
        address outboundLane = outboundLanes[outBoundId];
        require(outboundLane != address(0), "MappingTokenFactory:the outbound lane is not exist");
        uint256 fee = IFeeMarket(feeMarket).market_fee();
        require(msg.value >= fee, "MappingTokenFactory:not enough fee to pay");
        uint256 messageId = IOutboundLane(outboundLane).send_message{value: fee}(receiver, message);
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
        return messageId;
    }
}

