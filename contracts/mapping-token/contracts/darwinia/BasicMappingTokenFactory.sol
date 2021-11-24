// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/proxy/utils/Initializable.sol";
import "@zeppelin-solidity-4.4.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@darwinia/contracts-utils/contracts/DailyLimit.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "@darwinia/contracts-utils/contracts/Pausable.sol";
import "../interfaces/IERC20.sol";
import "./MappingTokenAddress.sol";

contract BasicMappingTokenFactory is Initializable, Ownable, DailyLimit, MappingTokenAddress, Pausable {
    struct OriginalInfo {
        // 0 - NativeToken
        // 1 - Erc20Token
        // ...
        uint32  tokenType;
        address backing_address;
        address original_token;
    }
    // the mapping token list
    address[] public allMappingTokens;
    // salt=>mapping_token, the salt is derived from origin token on backing chain
    // so this is a mapping from origin to mapping token
    mapping(bytes32 => address) public salt2MappingToken;
    // mapping_token=>info the info is the original token info
    // so this is a mapping from mapping_token to original token
    mapping(address => OriginalInfo) public mappingToken2OriginalInfo;
    // tokenType=>Logic
    // tokenType comes from original token, the logic contract is used to create the mapping-token contract
    mapping(uint32 => address) public tokenType2Logic;

    event NewLogicSetted(uint32 tokenType, address addr);
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

    function setDailyLimit(address mapping_token, uint amount) public onlyOwner  {
        _setDailyLimit(mapping_token, amount);
    }

    function changeDailyLimit(address mapping_token, uint amount) public onlyOwner  {
        _changeDailyLimit(mapping_token, amount);
    }

    function setTokenContractLogic(uint32 tokenType, address logic) external onlyOwner {
        tokenType2Logic[tokenType] = logic;
        emit NewLogicSetted(tokenType, logic);
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function transferMappingTokenOwnership(address mapping_token, address new_owner) external onlyOwner {
        Ownable(mapping_token).transferOwnership(new_owner);
    }

    // add new mapping token address
    function addMappingToken(address backing_address, address original_token, address mapping_token, uint32 token_type) external onlyOwner {
        bytes32 salt = keccak256(abi.encodePacked(backing_address, original_token));
        address existed = salt2MappingToken[salt];
        require(existed == address(0), "the mapping token exist");
        allMappingTokens.push(mapping_token);
        mappingToken2OriginalInfo[mapping_token] = OriginalInfo(token_type, backing_address, original_token);
        salt2MappingToken[salt] = mapping_token;
        emit MappingTokenUpdated(salt, existed, mapping_token);
    }

    // update the mapping token address when the mapping token contract deployed before
    function updateMappingToken(address backing_address, address original_token, address new_mapping_token, uint index) external onlyOwner {
        bytes32 salt = keccak256(abi.encodePacked(backing_address, original_token));
        address existed = salt2MappingToken[salt];
        require(salt2MappingToken[salt] != address(0), "the mapping token not exist");
        require(tokenLength() > index && allMappingTokens[index] == existed, "invalid index");
        allMappingTokens[index] = new_mapping_token;
        OriginalInfo memory info = mappingToken2OriginalInfo[existed];
        delete mappingToken2OriginalInfo[existed];
        mappingToken2OriginalInfo[new_mapping_token] = info;
        salt2MappingToken[salt] = new_mapping_token;
        emit MappingTokenUpdated(salt, existed, new_mapping_token);
    }

    // internal
    function deploy(bytes32 salt, bytes memory code) internal returns (address addr) {
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    // view
    function tokenLength() public view returns (uint) {
        return allMappingTokens.length;
    }

    function mappingToken(address backing_address, address original_token) public view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(backing_address, original_token));
        return salt2MappingToken[salt];
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
    ) public virtual onlySystem whenNotPaused returns (address mapping_token) {
        require(tokenType == 0 || tokenType == 1, "token type cannot mapping to erc20 token");
        // backing_address and original_token pack a unique new contract salt
        bytes32 salt = keccak256(abi.encodePacked(backing_address, original_token));
        require(salt2MappingToken[salt] == address(0), "contract has been deployed");
        bytes memory bytecode = type(TransparentUpgradeableProxy).creationCode;
        bytes memory bytecodeWithInitdata = abi.encodePacked(bytecode, abi.encode(tokenType2Logic[tokenType], address(DEAD_ADDRESS), ""));
        mapping_token = deploy(salt, bytecodeWithInitdata);
        IMappingToken(mapping_token).initialize(name, symbol, decimals);

        salt2MappingToken[salt] = mapping_token;
        // save the mapping tokens in an array so it can be listed
        allMappingTokens.push(mapping_token);
        // map the mapping_token to origin info
        mappingToken2OriginalInfo[mapping_token] = OriginalInfo(tokenType, backing_address, original_token);
        emit IssuingERC20Created(backing_address, original_token, mapping_token);
    }

    function issueMappingToken(address mapping_token, address recipient, uint256 amount) public virtual onlySystem whenNotPaused {
        require(amount > 0, "can not receive amount zero");
        OriginalInfo memory info = mappingToken2OriginalInfo[mapping_token];
        require(info.original_token != address(0), "token is not created by factory");
        expendDailyLimit(mapping_token, amount);
        IERC20(mapping_token).mint(recipient, amount);
    }
}

