// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/access/AccessControlEnumerable.sol";
import "@zeppelin-solidity-4.4.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@zeppelin-solidity-4.4.0/contracts/proxy/utils/Initializable.sol";
import "@zeppelin-solidity-4.4.0/contracts/security/Pausable.sol";
import "../interfaces/ICrossChainFilter.sol";
import "../interfaces/IFeeMarket.sol";
import "../interfaces/IInboundLane.sol";
import "../interfaces/IMessageCommitment.sol";
import "../interfaces/IOutboundLane.sol";

contract HelixApp is AccessControlEnumerable, Initializable, ICrossChainFilter, Pausable {
    bytes32 public constant DAO_ADMIN_ROLE = keccak256("DAO_ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE  = keccak256("OPERATOR_ROLE");

    address public feeMarket;
    string  public thisChainName;
    uint32  public remoteChainPosition;
    address public remoteHelix;

    // bridge channel
    // bridgedLanePosition => inBoundLaneAddress
    mapping(uint32 => address) public inboundLanes;
    // bridgedLanePosition => outBoundLaneAddress
    mapping(uint32 => address) public outboundLanes;

    event NewInBoundLaneAdded(address backingAddress, address inboundLane);
    event NewOutBoundLaneAdded(uint32 bridgedLanePosition, address outboundLane);

    // access controller
    // admin is helix Dao
    modifier onlyAdmin() {
        require(hasRole(DAO_ADMIN_ROLE, msg.sender), "HelixApp:Bad admin role");
        _;
    }

    // operator
    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "HelixApp:Bad operator role");
        _;
    }

    //modifier onlyInBoundLane(address mappingTokenFactoryAddress) {
    modifier onlyRemoteHelix(address _remoteHelix) {
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(msg.sender).getLaneInfo();
        require(remoteChainPosition == bridgedChainPosition, "HelixApp:Invalid bridged chain position");
        require(remoteHelix == _remoteHelix, "HelixApp:remote caller is not helix sender allowed");
        require(inboundLanes[bridgedLanePosition] == msg.sender, "HelixApp:caller is not the inboundLane account");
        _;
    }

    modifier onlyOutBoundLane() {
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(msg.sender).getLaneInfo();
        require(remoteChainPosition == bridgedChainPosition, "HelixApp:Invalid bridged chain position");
        require(outboundLanes[bridgedLanePosition] == msg.sender, "HelixApp:caller is not the outboundLane account");
        _;
    }

    // after initialize, msg.sender should set Dao as DAO_ADMIN_ROLE and renounceRole
    function initialize(uint32 _bridgedChainPosition, address _remoteHelix, address _feeMarket, string memory _chainName) public initializer {
        feeMarket = _feeMarket;
        remoteChainPosition = _bridgedChainPosition;
        remoteHelix = _remoteHelix;
        thisChainName = _chainName;
        _setRoleAdmin(OPERATOR_ROLE, DAO_ADMIN_ROLE);
        _setRoleAdmin(DAO_ADMIN_ROLE, DAO_ADMIN_ROLE);
        _setupRole(DAO_ADMIN_ROLE, msg.sender);
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function pause() external onlyOperator {
        _pause();
    }

    function updateFeeMarket(address newFeeMarket) external onlyAdmin {
        feeMarket = newFeeMarket;
    }

    // here add InBoundLane, and remote issuing module must add the corresponding OutBoundLane
    function addInboundLane(address mappingTokenFactory, address inboundLane) external onlyAdmin {
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(inboundLane).getLaneInfo();
        require(remoteChainPosition == bridgedChainPosition, "HelixApp:Invalid bridged chain position");
        inboundLanes[bridgedLanePosition] = inboundLane;
        emit NewInBoundLaneAdded(mappingTokenFactory, inboundLane);
    }

    // here add OutBoundLane, and remote issuing module must add the corresponding InBoundLane
    function addOutboundLane(address outboundLane) external onlyAdmin {
        (,,uint32 bridgedChainPosition, uint32 bridgedLanePosition) = IMessageCommitment(outboundLane).getLaneInfo();
        require(remoteChainPosition == bridgedChainPosition, "HelixApp:Invalid bridged chain position");
        outboundLanes[bridgedLanePosition] = outboundLane;
        emit NewOutBoundLaneAdded(bridgedLanePosition, outboundLane);
    }

    function crossChainFilter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address sourceAccount,
        bytes calldata
    ) external view returns (bool) {
        return remoteChainPosition == bridgedChainPosition && inboundLanes[bridgedLanePosition] == msg.sender && remoteHelix == sourceAccount;
    }

    function _sendMessage(
        uint32 bridgedLanePosition,
        bytes memory message
    ) internal returns(uint256) {
        address outboundLane = outboundLanes[bridgedLanePosition];
        require(outboundLane != address(0), "HelixApp:cannot find outboundLane to send message");
        uint256 fee = IFeeMarket(feeMarket).market_fee();
        require(msg.value >= fee, "HelixApp:not enough fee to pay");
        uint256 messageId = IOutboundLane(outboundLane).send_message{value: fee}(remoteHelix, message);
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
        return messageId;
    }
}
 
