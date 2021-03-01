// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./common/Scale.sol";
import "./common/Ownable.sol";
import { ScaleStruct } from "./common/Scale.struct.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IRelay.sol";

contract Backing is Initializable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct BridgerInfo {
        address target;
        uint256 timestamp;
    }

    receive() external payable {
        assert(msg.sender == weth);
    }

    //uint256 public registerFee = 0;
    IRelay public relay;
    address public weth;
    bytes public storageKey;

    mapping(address => BridgerInfo) private assets;
    mapping(uint32 => address) public history;

    event NewTokenRegisted(address indexed token, uint256 timestamp);
    event BackingLock(address indexed token, uint256 amount, address receiver);
    event VerifyProof(uint32 blocknumber);
    event RegistCompleted(address sender, address token, address target);
    event RedeemTokenEvent(address sender, address token, address target, address receipt, uint256 amount);

    function initialize(address _relay, address _weth) public initializer {
        ownableConstructor();
        relay = IRelay(_relay);
        weth = _weth;
    }

    function setStorageKey(bytes memory key) external onlyOwner {
        storageKey = key;
    }

    function registerToken(address token) external {
        require(assets[token].timestamp == 0, "asset has been registed");
        assets[token] = BridgerInfo(address(0), block.timestamp);
        emit NewTokenRegisted(token, block.timestamp);
    }

    function crossSendToken(address token, address recipient, uint256 amount) external {
        require(amount > 0, "balance is zero");
        require(assets[token].target != address(0), "asset has not been registed");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit BackingLock(token, amount, recipient);
    }

    function crossSendETH(address recipient) external payable {
        require(msg.value > 0, "balance cannot be zero");
        require(assets[weth].target != address(0), "weth has not been registed");
        IWETH(weth).deposit{value: msg.value}();
        emit BackingLock(weth, msg.value, recipient);
    }

    function crossChainSync(
        bytes memory message,
        bytes[] memory signatures,
        bytes32 root,
        uint32 MMRIndex,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory eventsProofStr
    ) public {
        if(relay.getMMRRoot(MMRIndex) == bytes32(0)) {
            relay.appendRoot(message, signatures);
        }
        verifyProof(root, MMRIndex, blockHeader, peaks, siblings, eventsProofStr);
    }

    function verifyProof(
        bytes32 root,
        uint32 MMRIndex,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory eventsProofStr
    ) public {
        uint32 blockNumber = Scale.decodeBlockNumberFromBlockHeader(blockHeader);

        require(history[blockNumber] == address(0), "TokenBacking:: verifyProof:  The block has been verified");

        Input.Data memory data = Input.from(relay.verifyRootAndDecodeReceipt(root, MMRIndex, blockNumber, blockHeader, peaks, siblings, eventsProofStr, storageKey));
        
        ScaleStruct.TokenBurnEvent[] memory events = Scale.decodeTokenBurnEvent(data);

        uint256 len = events.length;
        for( uint i = 0; i < len; i++ ) {
          ScaleStruct.TokenBurnEvent memory item = events[i];
          if (item.eventType == 1) {
              processRedeemEvent(item);
          } else if (item.eventType == 0) {
              processRegisterResponse(item);
          }
        }

        history[blockNumber] = msg.sender;
        emit VerifyProof(blockNumber);
    }

    function processRedeemEvent(ScaleStruct.TokenBurnEvent memory item) internal {
        uint256 value = item.value;
        address token = item.token;
        address target = item.target;
        if (assets[token].target == target) {
            // assetType == 0: native, 1: token
            if (token == weth && item.assetType == 0) {
                IWETH(weth).withdraw(value);
                item.recipient.transfer(value);
            } else {
                IERC20(token).safeTransfer(item.recipient, value);
            }
            emit RedeemTokenEvent(item.sender, token, target, item.recipient, value);
        }
    }

    function processRegisterResponse(ScaleStruct.TokenBurnEvent memory item) internal {
        address token = item.token;
        require(assets[token].timestamp != 0, "asset is not existed");
        require(assets[token].target == address(0), "asset has been responsed");
        address target = item.target;
        assets[token].target = target;
        emit RegistCompleted(item.sender, token, target);
    }
}

