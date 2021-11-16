// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@darwinia/contracts-utils/contracts/Scale.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "@darwinia/contracts-bridge/contracts/ethereum/v2/interfaces/IOutboundChannel.sol";
import "@darwinia/contracts-bridge/contracts/ethereum/v2/interfaces/ICrossChainFilter.sol";
import "../interfaces/IERC20Option.sol";
import "../interfaces/IERC20Bytes32Option.sol";
import '../interfaces/IWETH.sol';

contract Backing is ICrossChainFilter, Initializable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct BridgerInfo {
        address target;
        uint256 timestamp;
    }

    struct Fee {
        address token;
        uint256 fee;
    }

    // bytes4(keccak256('registerToken(address,string,string,uint8)')) == 0xea3aca6f
    bytes4 public constant REGISTRY_CALL = 0xea3aca6f;

    // bytes4(keccak256('mint(address,address,uint256)')) == 0xc6c3bbe6
    bytes4 public constant MINT_CALL = 0xc6c3bbe6;

    address public inbound;
    address public outbound;
    address public WETH;
    Fee public registerFee;
    Fee public transferFee;

    mapping(address => BridgerInfo) public assets;
    mapping(uint32 => address) public history;
    address[] public allAssets;

    event NewTokenRegistered(address indexed token, string name, string symbol, uint8 decimals, uint256 fee);
    event BackingLock(address indexed sender, address source, address target, uint256 amount, address receiver, uint256 fee);
    event RegistCompleted(address token, address target);
    event RedeemTokenEvent(address token, address target, address receipt, uint256 amount);

    modifier onlyInbound() {
        require(inbound == msg.sender, "only inbound");
        _;
    }

    modifier register(address token) {
        require(assets[token].timestamp == 0, "asset has been registered");
        if (registerFee.fee > 0) {
            IERC20(registerFee.token).safeTransferFrom(msg.sender, address(this), registerFee.fee);
            IERC20Option(registerFee.token).burn(address(this), registerFee.fee);
        }
        assets[token] = BridgerInfo(address(0), block.timestamp);
        allAssets.push(token);
        _;
    }

    function initialize(address _inbound, address _outbound, address _WETH, address _registerFeeToken, address _transferFeeToken) public initializer {
        ownableConstructor();
        inbound = _inbound;
        outbound = _outbound;
        WETH = _WETH;
        registerFee = Fee(_registerFeeToken, 0);
        transferFee = Fee(_transferFeeToken, 0);
    }

    function setChannel(address _inbound, address _outbound) external onlyOwner {
        inbound = _inbound;
        outbound = _outbound;
    }

    function setRegisterFee(address token, uint256 fee) external onlyOwner {
        registerFee.token = token;
        registerFee.fee = fee;
    }

    function setTransferFee(address token, uint256 fee) external onlyOwner {
        transferFee.token = token;
        transferFee.fee = fee;
    }

    function assetLength() external view returns (uint) {
        return allAssets.length;
    }

    function encodeRegistryAndSubmit(
        address _token,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal {
        bytes memory call = abi.encodeWithSelector(REGISTRY_CALL, _token, _name, _symbol, _decimals);
        IOutboundChannel(outbound).submit(call);
    }

    function encodeMintAndSubmit(
        address _token,
        address _recipient,
        uint256 _amount
    ) internal {
        bytes memory call = abi.encodeWithSelector(MINT_CALL, _token, _recipient, _amount);
        IOutboundChannel(outbound).submit(call);
    }

    function registerToken(address token) external register(token) {
        string memory name = IERC20Option(token).name();
        string memory symbol = IERC20Option(token).symbol();
        uint8 decimals = IERC20Option(token).decimals();
        encodeRegistryAndSubmit(token, name, symbol, decimals);
        emit NewTokenRegistered(
            token,
            name,
            symbol,
            decimals,
            registerFee.fee
        );
    }

    function registerTokenBytes32(address token) external register(token) {
        string memory name = string(abi.encodePacked(IERC20Bytes32Option(token).name()));
        string memory symbol = string(abi.encodePacked(IERC20Bytes32Option(token).symbol()));
        uint8 decimals = uint8(IERC20Bytes32Option(token).decimals());
        encodeRegistryAndSubmit(token, name, symbol, decimals);
        emit NewTokenRegistered(
            token,
            name,
            symbol,
            decimals,
            registerFee.fee
        );
    }

    function registerTokenWithName(address token, string memory name, string memory symbol, uint8 decimals) public onlyOwner register(token) {
        encodeRegistryAndSubmit(token, name, symbol, decimals);
        emit NewTokenRegistered(
            token,
            name,
            symbol,
            decimals,
            registerFee.fee
        );
    }

    function crossSendToken(address token, address recipient, uint256 amount) external payable {
        require(amount > 0, "balance is zero");
        require(assets[token].target != address(0), "asset has not been registered");
        if (transferFee.fee > 0) {
            IERC20(transferFee.token).safeTransferFrom(msg.sender, address(this), transferFee.fee);
            IERC20Option(transferFee.token).burn(address(this), transferFee.fee);
        }
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        encodeMintAndSubmit(token, recipient, amount);
        emit BackingLock(msg.sender, token, assets[token].target, amount, recipient, transferFee.fee);
    }

    function redeem(address backing, address token, address target, address payable recipient, uint256 value) external onlyInbound() {
        require(assets[token].target == target, "the mapped address uncorrect");
        require(backing == address(this), "not the expected backing");
        IERC20(token).safeTransfer(recipient, value);
        emit RedeemTokenEvent(token, target, recipient, value);
    }

    // TODO: may could calc the targe address before the response
    function registerResponse(address backing, address token, address target) external onlyInbound() {
        require(assets[token].timestamp != 0, "asset is not existed");
        require(assets[token].target == address(0), "asset has been responsed");
        require(backing == address(this), "not the expected backing");
        assets[token].target = target;
        emit RegistCompleted(token, target);
    }

    // TODO: ensure sourceAccount is right
    function crossChainFilter(address sourceAccount, bytes memory) public override view returns (bool) {
        require(sourceAccount == address(0), "invalid source account");
        return true;
    }
}

