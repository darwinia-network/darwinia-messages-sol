// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/proxy/utils/Initializable.sol";
import "@zeppelin-solidity-4.4.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@zeppelin-solidity-4.4.0/contracts/utils/math/SafeMath.sol";
import "../interfaces/ICrossChainFilter.sol";
import "../interfaces/IFeeMarket.sol";
import "../interfaces/IMessageCommitment.sol";
import "../interfaces/IOutboundLane.sol";
import "../../utils/Ownable.sol";
import "../../utils/Pausable.sol";
import "../interfaces/IInboundLane.sol";

contract Backing is Initializable, Ownable, ICrossChainFilter, Pausable {
    using SafeMath for uint256;
    struct InBoundLaneInfo {
        address remoteSender;
        address inBoundLaneAddress;
    }
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

    event NewInBoundLaneAdded(address backingAddress, address inboundLane);
    event NewOutBoundLaneAdded(uint32 bridgedLanePosition, address outboundLane);

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

    function updateFeeMarket(address newFeeMarket) external onlyOwner {
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

    function crossChainFilter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address sourceAccount,
        bytes calldata
    ) external view returns (bool) {
        return remoteChainPosition == bridgedChainPosition && inboundLanes[bridgedLanePosition] == msg.sender && remoteMappingTokenFactory == sourceAccount;
    }

    function sendMessage(
        uint32 bridgedLanePosition,
        address remoteMappingTokenFactory,
        bytes memory message
    ) internal returns(uint256) {
        address outboundLane = outboundLanes[bridgedLanePosition];
        require(outboundLane != address(0), "Backing:cannot find outboundLane to send message");
        uint256 fee = IFeeMarket(feeMarket).market_fee();
        require(msg.value >= fee, "Backing:not enough fee to pay");
        uint256 messageId = IOutboundLane(outboundLane).send_message{value: fee}(remoteMappingTokenFactory, message);
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value.sub(fee));
        }
        return messageId;
    }
}
 
