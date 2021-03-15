// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "./common/Ownable.sol";

contract MappingTokenFactory is Initializable, Ownable {
    address public constant REGISTER_PRECOMPILE = 0x0000000000000000000000000000000000000016;
    address public admin;
    address[] public allTokens;
    mapping(bytes32 => address payable) public tokenMap;
    mapping(string => address) public logic;

    string constant LOGIC_ERC20 = "erc20";

    event NewLogicSetted(string name, address addr);
    event IssuingERC20Created(address indexed sender, address backing, address source, address token);

    function initialize() public initializer {
        ownableConstructor();
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function setERC20Logic(address _logic) external onlyOwner {
        logic[LOGIC_ERC20] = _logic;
        emit NewLogicSetted(LOGIC_ERC20, _logic);
    }

    function deploy(bytes32 salt, bytes memory code) internal returns (address payable addr) {
        bytes32 newsalt = keccak256(abi.encodePacked(salt, msg.sender)); 
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), newsalt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    function createERC20Contract(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address backing,
        address source
    ) external onlyOwner returns (address payable token) {
        bytes32 salt = keccak256(abi.encodePacked(backing, source));
        require(tokenMap[salt] == address(0), "contract has been deployed");
        bytes memory bytecode = type(TransparentUpgradeableProxy).creationCode;
        bytes memory erc20initdata = 
            abi.encodeWithSignature("initialize(string,string,uint8,address,address)",
                                    name,
                                    symbol,
                                    decimals,
                                    backing,
                                    source);
        bytes memory bytecodeWithInitdata = abi.encodePacked(bytecode, abi.encode(logic[LOGIC_ERC20], admin, erc20initdata));
        token = deploy(salt, bytecodeWithInitdata);
        Ownable(token).transferOwnership(msg.sender);
        tokenMap[salt] = token;
        allTokens.push(token);
        (bool success, ) = REGISTER_PRECOMPILE.call(abi.encode(backing, source, token));
        require(success, "create: call create erc20 precompile failed");
        emit IssuingERC20Created(msg.sender, backing, source, token);
    }

    function tokenLength() external view returns (uint) {
        return allTokens.length;
    }

    function mappingToken(address backing, address source) public view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(backing, source));
        return tokenMap[salt];
    }
}

