// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./common/Scale.sol";
import "./common/Ownable.sol";
import { ScaleStruct } from "./common/Scale.struct.sol";
import "./interfaces/IRelay.sol";
import "./interfaces/IERC20Option.sol";

contract Backing is Initializable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct BridgerInfo {
        address target;
        uint256 timestamp;
    }

    uint256 public registerFee = 0;
    uint256 public feeReserved = 0;
    address feeToken;
    IRelay public relay;
    bytes public substrateEventStorageKey;

    mapping(address => BridgerInfo) public assets;
    mapping(uint32 => address) public history;

    event NewTokenRegistered(address indexed token, string name, string symbol, uint8 decimals);
    event BackingLock(address indexed token, address target, uint256 amount, address receiver);
    event VerifyProof(uint32 blocknumber);
    event RegistCompleted(address token, address target);
    event RedeemTokenEvent(address token, address target, address receipt, uint256 amount);

    function initialize(address _relay, address _feeToken) public initializer {
        ownableConstructor();
        relay = IRelay(_relay);
        feeToken = _feeToken;
    }

    function setStorageKey(bytes memory key) external onlyOwner {
        substrateEventStorageKey = key;
    }

    function registerToken(address token) external {
        require(assets[token].timestamp == 0, "asset has been registered");
        if (registerFee > 0) {
            IERC20(feeToken).safeTransferFrom(msg.sender, address(this), registerFee);
            feeReserved += registerFee;
        }
        assets[token] = BridgerInfo(address(0), block.timestamp);

        string memory name = IERC20Option(token).name();
        string memory symbol = IERC20Option(token).symbol();
        uint8 decimals = IERC20Option(token).decimals();
        emit NewTokenRegistered(
            token,
            name,
            symbol,
            decimals
        );
    }

    function crossSendToken(address token, address recipient, uint256 amount) external {
        require(amount > 0, "balance is zero");
        require(assets[token].target != address(0), "asset has not been registered");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit BackingLock(token, assets[token].target, amount, recipient);
    }

    // This function receives two kind of event proof from darwinia
    // One is token register response proof, and use it to confirm the mapped contract address on darwinia
    // the other is token burn event proof from darwinia, and use it to redeem asset locked on ethereum
    // it use relay contract to proof the event and it's block. 
    // So if the mmr root has not been appended to relay. we must append it first.
    // Once the event is proved valid. We decode it and `save the mapped address`/`unlock users token`

    // params:
    // message - bytes3 prefix + uint32 mmr-index + bytes32 mmr-root
    // signatures - the signatures for mmr-root message
    // root - mmr root for the block
    // MMRIndex - mmr index of the block
    // blockNumber, blockHeader - The block where the event occured on darwinia network
    // can be fetched by api.rpc.chain.getHeader('block hash') 
    // peaks, siblings - mmr proof for the blockNumber, like a merkle proof
    // eventsProofStr - mpt proof for events Vec<Vec<u8>> encoded by Scale codec
    // Notes: params can be getted by bridger's[https://github.com/darwinia-network/bridger] command `info-d2e`
    function crossChainSync(
        bytes memory message,
        bytes[] memory signatures,
        bytes32 root,
        uint32 MMRIndex,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory eventsProofStr
    ) public returns(ScaleStruct.IssuingEvent[] memory) {
        if(relay.getMMRRoot(MMRIndex) == bytes32(0)) {
            relay.appendRoot(message, signatures);
        }
        return verifyProof(root, MMRIndex, blockHeader, peaks, siblings, eventsProofStr);
    }

    // This function is called by crossChainSync
    // or you can call it directly if the mmr root has been appended to relay
    function verifyProof(
        bytes32 root,
        uint32 MMRIndex,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory eventsProofStr
    ) public returns(ScaleStruct.IssuingEvent[] memory) {
        uint32 blockNumber = Scale.decodeBlockNumberFromBlockHeader(blockHeader);

        require(history[blockNumber] == address(0), "TokenBacking:: verifyProof:  The block has been verified");

        Input.Data memory data = Input.from(relay.verifyRootAndDecodeReceipt(root, MMRIndex, blockNumber, blockHeader, peaks, siblings, eventsProofStr, substrateEventStorageKey));
        
        ScaleStruct.IssuingEvent[] memory events = Scale.decodeIssuingEvent(data);

        uint256 len = events.length;
        for( uint i = 0; i < len; i++ ) {
          ScaleStruct.IssuingEvent memory item = events[i];
          if (item.eventType == 1) {
              processRedeemEvent(item);
          } else if (item.eventType == 0) {
              processRegisterResponse(item);
          }
        }

        history[blockNumber] = msg.sender;
        emit VerifyProof(blockNumber);
        return events;
    }

    function processRedeemEvent(ScaleStruct.IssuingEvent memory item) internal {
        uint256 value = item.value;
        address token = item.token;
        address target = item.target;
        require(assets[token].target == target, "the mapped address uncorrect");
        require(item.backing == address(this), "not the expected backing");
        address receiver = (item.delegator == address(0) ? item.recipient : item.delegator);
        IERC20(token).safeTransfer(receiver, value);
        emit RedeemTokenEvent(token, target, receiver, value);
    }

    function processRegisterResponse(ScaleStruct.IssuingEvent memory item) internal {
        address token = item.token;
        require(assets[token].timestamp != 0, "asset is not existed");
        require(assets[token].target == address(0), "asset has been responsed");
        require(item.backing == address(this), "not the expected backing");
        address target = item.target;
        assets[token].target = target;
        emit RegistCompleted(token, target);
    }

    function setRegisterFee(uint256 fee) external onlyOwner {
        registerFee = fee;
    }

    function claimFee() external onlyOwner {
        uint256 balance = IERC20(feeToken).balanceOf(address(this));
        require(balance >= feeReserved && feeReserved > 0, "balance invalid");
        IERC20(feeToken).safeTransfer(msg.sender, feeReserved);
        feeReserved = 0;
    }
}

