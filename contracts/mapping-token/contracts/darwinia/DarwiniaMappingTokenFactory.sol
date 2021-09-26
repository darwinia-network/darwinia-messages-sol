// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "@darwinia/contracts-utils/contracts/DailyLimit.sol";
import "@darwinia/contracts-utils/contracts/Ownable.sol";
import "../interfaces/IERC20.sol";

contract DarwiniaMappingTokenFactory is Initializable, Ownable, DailyLimit {
    address public constant DISPATCH_ENCODER = 0x0000000000000000000000000000000000000018;
    address public constant DISPATCH         = 0x0000000000000000000000000000000000000019;
    // This system account is derived from the dvm pallet id `dar/dvmp`,
    // and it has no private key, it comes from internal transaction in dvm.
    address public constant SYSTEM_ACCOUNT   = 0x6D6F646C6461722f64766D700000000000000000;
    struct TokenInfo {
        bytes4 eventReceiver;
        // 0 - Erc20Token
        // 1 - NativeToken
        // ...
        uint32  tokenType;
        address backing_address;
        address original_token;
    }
    struct UnconfirmedInfo {
        address sender;
        address mapping_token;
        uint256 amount;
    }
    address public admin;
    address[] public allTokens;
    mapping(bytes32 => address payable) public tokenMap;
    mapping(address => TokenInfo) public tokenToInfo;
    mapping(string => address) public logic;
    mapping(bytes => UnconfirmedInfo) public transferUnconfirmed;
    string public issuing_chain_name;

    string constant LOGIC_ERC20 = "erc20";

    event NewLogicSetted(string name, address addr);
    event IssuingERC20Created(address indexed sender, address backing_address, address original_token, address mapping_token);
    event BurnAndWaitingConfirm(bytes message_id, address sender, bytes receipt, address token, uint256 amount);
    event RemoteUnlockConfirmed(bytes message_id, address sender, address token, uint256 amount, bool result);

    receive() external payable {
    }

    function initialize(string memory _issuing_chain_name) public initializer {
        ownableConstructor();
        issuing_chain_name = _issuing_chain_name;
    }

    /**
     * @dev Throws if called by any account other than the system account defined by SYSTEM_ACCOUNT address.
     */
    modifier onlySystem() {
        require(SYSTEM_ACCOUNT == msg.sender, "System: caller is not the system account");
        _;
    }

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

    function deploy(bytes32 salt, bytes memory code) internal returns (address payable addr) {
        bytes32 newsalt = keccak256(abi.encodePacked(salt, msg.sender)); 
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), newsalt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    function createERC20Contract(
        bytes4 eventReceiver,
        uint32 tokenType,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address backing_address,
        address original_token,
        string memory backing_chain_name
    ) external onlySystem returns (address payable mapping_token) {
        bytes32 salt = keccak256(abi.encodePacked(backing_address, original_token));
        require(tokenMap[salt] == address(0), "contract has been deployed");
        bytes memory bytecode = type(TransparentUpgradeableProxy).creationCode;
        bytes memory erc20initdata = 
            abi.encodeWithSignature("initialize(string,string,uint8)",
                                    string(abi.encodePacked(name, "(", backing_chain_name, ">", issuing_chain_name, ")")),
                                    symbol,
                                    decimals);
        bytes memory bytecodeWithInitdata = abi.encodePacked(bytecode, abi.encode(logic[LOGIC_ERC20], admin, erc20initdata));
        mapping_token = deploy(salt, bytecodeWithInitdata);
        tokenMap[salt] = mapping_token;
        allTokens.push(mapping_token);
        tokenToInfo[mapping_token] = TokenInfo(eventReceiver, tokenType, backing_address, original_token);

        (bool encodeSuccess, bytes memory encoded) = DISPATCH_ENCODER.call(
            abi.encodePacked(eventReceiver, bytes4(keccak256("token_register_response()")),
                             abi.encode(backing_address, original_token, mapping_token)));
        require(encodeSuccess, "create: encode dispatch failed");

        // for sub<>sub bridge, we don't need return the register response, so the encoder above return an empty call
        // for ethereum<>darwinia bridge, the encoded call is `register_response_from_contract`
        if (encoded.length > 0) {
            (bool success, ) = DISPATCH.call(encoded);
            require(success, "create: call create erc20 precompile failed");
        }
        emit IssuingERC20Created(msg.sender, backing_address, original_token, mapping_token);
    }

    function tokenLength() external view returns (uint) {
        return allTokens.length;
    }

    function mappingToken(address backing_address, address original_token) public view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(backing_address, original_token));
        return tokenMap[salt];
    }

    function crossReceive(address mapping_token, address recipient, uint256 amount) external onlySystem {
        require(amount > 0, "can not receive amount zero");
        TokenInfo memory info = tokenToInfo[mapping_token];
        require(info.original_token != address(0), "token is not created by factory");
        expendDailyLimit(mapping_token, amount);
        IERC20(mapping_token).mint(recipient, amount);
    }
    
    // cross transfer to remote chain without waiting any confirm information,
    // this require the burn proof can be always verified by the remote chain corrently.
    // so, here the user's token burned directly.
    function burnAndRemoteUnlock(uint32 specVersion, uint64 weight, address mapping_token, bytes memory recipient, uint256 amount) external payable {
        burnAndSendProof(specVersion, weight, mapping_token, recipient, amount);
        IERC20(mapping_token).burn(address(this), amount);
    }

    // Step 1: User lock the mapped token to this contract and waiting the remote backing's unlock result.
    function burnAndRemoteUnlockWaitingConfirm(uint32 specVersion, uint64 weight, address mapping_token, bytes memory recipient, uint256 amount) external payable {
        burnAndSendProof(specVersion, weight, mapping_token, recipient, amount);
        TokenInfo memory info = tokenToInfo[mapping_token];
        (bool readSuccess, bytes memory messageId) = DISPATCH_ENCODER.call(
            abi.encodePacked(info.eventReceiver, bytes4(keccak256("read_latest_message_id()")))
        );
        require(readSuccess, "burn: read message id failed");
        transferUnconfirmed[messageId] = UnconfirmedInfo(msg.sender, mapping_token, amount);
        emit BurnAndWaitingConfirm(messageId, msg.sender, recipient, mapping_token, amount);
    }

    // Step 2: The remote backing's unlock result comes. The result is true(success) or false(failure).
    // True:  if event is verified and the origin token unlocked successfully on remote chain, then we burn the mapped token
    // False: if event is verified, but the origin token unlocked on remote chain failed, then we take back the mapped token to user.
    function confirmBurnAndRemoteUnlock(bytes memory messageId, bool result) external onlySystem {
        UnconfirmedInfo memory info = transferUnconfirmed[messageId];
        require(info.amount > 0 && info.sender != address(0) && info.mapping_token != address(0), "invalid unconfirmed message");
        if (result) {
            IERC20(info.mapping_token).burn(address(this), info.amount);
        } else {
            require(IERC20(info.mapping_token).transfer(info.sender, info.amount), "transfer back failed");
        }
        delete transferUnconfirmed[messageId];
        emit RemoteUnlockConfirmed(messageId, info.sender, info.mapping_token, info.amount, result);
    }

    function burnAndSendProof(uint32 specVersion, uint64 weight, address mapping_token, bytes memory recipient, uint256 amount) internal {
        require(amount > 0, "can not transfer amount zero");
        TokenInfo memory info = tokenToInfo[mapping_token];
        require(info.original_token != address(0), "token is not created by factory");
        // Lock the fund in this before message on remote backing chain get dispatched successfully and burn finally
        // If remote backing chain unlock the origin token successfully, then this fund will be burned.
        // Otherwise, this fund will be transfered back to the msg.sender.
        require(IERC20(mapping_token).transferFrom(msg.sender, address(this), amount), "transfer token failed");

        (bool encodeSuccess, bytes memory encoded) = DISPATCH_ENCODER.call(
            abi.encodePacked(info.eventReceiver, bytes4(keccak256("burn_and_remote_unlock()")),
                           abi.encode(specVersion,
                                      weight,
                                      info.tokenType,
                                      info.backing_address,
                                      msg.sender, 
                                      info.original_token,
                                      recipient, 
                                      amount,
                                      msg.value)));
        require(encodeSuccess, "burn: encode dispatch failed");
        (bool success, ) = DISPATCH.call(encoded);
        require(success, "burn: call burn precompile failed");
    }
}

