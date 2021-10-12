// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "@darwinia/contracts-utils/contracts/DailyLimit.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "../interfaces/IERC20.sol";
import "./MappingTokenAddress.sol";

contract BasicMappingTokenFactory is Initializable, Ownable, DailyLimit, MappingTokenAddress {
    struct TokenInfo {
        // 0 - Erc20Token
        // 1 - NativeToken
        // ...
        uint32  tokenType;
        address backing_address;
        address original_token;
    }
    address public admin;
    address[] public allTokens;
    mapping(bytes32 => address) public tokenMap;
    mapping(address => TokenInfo) public tokenToInfo;
    mapping(string => address) public logic;

    string constant LOGIC_ERC20 = "erc20";

    event NewLogicSetted(string name, address addr);
    event IssuingERC20Created(address backing_address, address original_token, address mapping_token);
    event MappingTokenUpdated(bytes32 salt, address old_address, address new_address);

    receive() external payable {
    }

    function initialize() public initializer {
        ownableConstructor();
    }

    /**
     * @dev Throws if called by any account other than the system account defined by SYSTEM_ACCOUNT address.
     */
    modifier onlySystem() {
        require(SYSTEM_ACCOUNT == msg.sender, "System: caller is not the system account");
        _;
    }

    // only owner settings
    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function setDailyLimit(address mapping_token, uint amount) public onlyOwner  {
        _setDailyLimit(mapping_token, amount);
    }

    function changeDailyLimit(address mapping_token, uint amount) public onlyOwner  {
        _changeDailyLimit(mapping_token, amount);
    }

    function setERC20Logic(address _logic) external onlyOwner {
        logic[LOGIC_ERC20] = _logic;
        emit NewLogicSetted(LOGIC_ERC20, _logic);
    }

    // update the mapping token address when the mapping token contract deployed before
    function updateMappingToken(address backing_address, address original_token, address mapping_token, uint index) external onlyOwner {
        bytes32 salt = keccak256(abi.encodePacked(backing_address, original_token));
        address existed = tokenMap[salt];
        require(tokenMap[salt] != address(0), "the mapping token not exist");
        require(tokenLength() > index && allTokens[index] == existed, "invalid index");
        allTokens[index] = mapping_token;
        tokenToInfo[mapping_token] = tokenToInfo[existed];
        delete tokenToInfo[existed];
        tokenMap[salt] = mapping_token;
        emit MappingTokenUpdated(salt, existed, mapping_token);
    }

    // internal
    function deploy(bytes32 salt, bytes memory code) internal returns (address addr) {
        bytes32 newsalt = keccak256(abi.encodePacked(salt, msg.sender, address(this)));
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), newsalt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    // view
    function tokenLength() public view returns (uint) {
        return allTokens.length;
    }

    function mappingToken(address backing_address, address original_token) public view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(backing_address, original_token));
        return tokenMap[salt];
    }

    // only system
    // create new erc20 mapping token contract
    // save and manage the token list
    function newErc20Contract(
        uint32 tokenType,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address backing_address,
        address original_token
    ) public virtual onlySystem returns (address mapping_token) {
        // backing_address and original_token pack a unique new contract salt
        bytes32 salt = keccak256(abi.encodePacked(backing_address, original_token));
        require(tokenMap[salt] == address(0), "contract has been deployed");
        bytes memory bytecode = type(TransparentUpgradeableProxy).creationCode;
        bytes memory erc20initdata = 
            abi.encodeWithSignature(
                "initialize(string,string,uint8)",
                name,
                symbol,
                decimals);
        bytes memory bytecodeWithInitdata = abi.encodePacked(bytecode, abi.encode(logic[LOGIC_ERC20], admin, erc20initdata));
        mapping_token = deploy(salt, bytecodeWithInitdata);
        tokenMap[salt] = mapping_token;
        // save the mapping tokens in an array so it can be listed
        allTokens.push(mapping_token);
        // map the mapping_token to origin info
        tokenToInfo[mapping_token] = TokenInfo(tokenType, backing_address, original_token);
        emit IssuingERC20Created(backing_address, original_token, mapping_token);
    }

    function issueMappingToken(address mapping_token, address recipient, uint256 amount) external onlySystem {
        require(amount > 0, "can not receive amount zero");
        TokenInfo memory info = tokenToInfo[mapping_token];
        require(info.original_token != address(0), "token is not created by factory");
        expendDailyLimit(mapping_token, amount);
        IERC20(mapping_token).mint(recipient, amount);
    }
}

