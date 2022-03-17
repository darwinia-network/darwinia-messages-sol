// SPDX-License-Identifier: MIT
// This is the Issuing Module(Mapping-token-factory) of the ethereum like bridge.
// We trust the inboundLane/outboundLane when we add them to the module.
// It means that each message from the inboundLane is verified correct and truthly from the sourceAccount.
// Only we need is to verify the sourceAccount is expected. And we add it to the Filter.
pragma solidity ^0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../../utils/DailyLimit.sol";
import "../interfaces/IBacking.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IGuard.sol";
import "../interfaces/IInboundLane.sol";
import "../interfaces/IMappingTokenFactory.sol";
import "../interfaces/IMessageCommitment.sol";
import "./HelixApp.sol";
import "./MappingTokenFactory.sol";

contract FungibleMappingTokenFactory is HelixApp, DailyLimit, IMappingTokenFactory, MappingTokenFactory {
    address public constant BLACK_HOLE_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    struct UnconfirmedInfo {
        address sender;
        address mappingToken;
        uint256 amount;
    }
    // guard
    address public guard;
    mapping(uint256 => UnconfirmedInfo) public unlockRemoteUnconfirmed;

    // tokenType=>Logic
    // tokenType comes from original token, the logic contract is used to create the mapping-token contract
    mapping(uint32 => address) public tokenType2Logic;

    event NewLogicSetted(uint32 tokenType, address addr);
    event IssuingERC20Created(address originalToken, address mappingToken);
    event BurnAndWaitingConfirm(uint256 messageId, address sender, address recipient, address token, uint256 amount);
    event RemoteUnlockConfirmed(uint256 messageId, bool result);

    receive() external payable {
    }

    /**
     * @notice only admin can transfer the ownership of the mapping token from factory to other account
     * generally we should not do this. When we encounter a non-recoverable error, we temporarily transfer the privileges to a maintenance account.
     * @param mappingToken the address the mapping token
     * @param new_owner the new owner of the mapping token
     */
    function transferMappingTokenOwnership(address mappingToken, address new_owner) external onlyAdmin {
        _transferMappingTokenOwnership(mappingToken, new_owner);
    }

    function updateGuard(address newGuard) external onlyAdmin {
        guard = newGuard;
    }

    function changeDailyLimit(address mappingToken, uint amount) public onlyAdmin  {
        _changeDailyLimit(mappingToken, amount);
    }


    function setTokenContractLogic(uint32 tokenType, address logic) external onlyAdmin {
        tokenType2Logic[tokenType] = logic;
        emit NewLogicSetted(tokenType, logic);
    }

    /**
     * @notice create new erc20 mapping contract, this can only be called by inboundLane
     * @param backingAddress the backingAddress which send this message
     * @param tokenType the original token type
     * @param originalToken the original token address
     * @param name the name of the original erc20 token
     * @param symbol the symbol of the original erc20 token
     * @param decimals the decimals of the original erc20 token
     */
    function newErc20Contract(
        address backingAddress,
        uint32 tokenType,
        address originalToken,
        string memory bridgedChainName,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public onlyRemoteHelix(backingAddress) whenNotPaused returns (address mappingToken) {
        require(tokenType == 0 || tokenType == 1, "MappingTokenFactory:token type cannot mapping to erc20 token");
        // (bridgeChainId, backingAddress, originalToken) pack a unique new contract salt
        bytes32 salt = keccak256(abi.encodePacked(remoteChainPosition, backingAddress, originalToken));
        require(salt2MappingToken[salt] == address(0), "MappingTokenFactory:contract has been deployed");
        mappingToken = deployErc20Contract(salt, tokenType);
        IMappingToken(mappingToken).initialize(
            string(abi.encodePacked(name, "[", bridgedChainName, ">")),
            string(abi.encodePacked("x", symbol)),
            decimals);

        _addMappingToken(salt, originalToken, mappingToken);
        emit IssuingERC20Created(originalToken, mappingToken);
    }

    function deployErc20Contract(
        bytes32 salt,
        uint32 tokenType
    ) internal returns(address) {
        bytes memory bytecode = type(TransparentUpgradeableProxy).creationCode;
        bytes memory bytecodeWithInitdata = abi.encodePacked(bytecode, abi.encode(tokenType2Logic[tokenType], address(BLACK_HOLE_ADDRESS), ""));
        return _deploy(salt, bytecodeWithInitdata);
    }

    /**
     * @notice issue mapping token, only can be called by inboundLane
     * @param backingAddress the backingAddress which send this message
     * @param originalToken the original token address
     * @param recipient the recipient of the issued mapping token
     * @param amount the amount of the issued mapping token
     */
    function issueMappingToken(
        address backingAddress,
        address originalToken,
        address recipient,
        uint256 amount
    ) public onlyRemoteHelix(backingAddress) whenNotPaused {
        address mappingToken = getMappingToken(remoteChainPosition, backingAddress, originalToken);
        require(mappingToken != address(0), "MappingTokenFactory:mapping token has not created");
        require(amount > 0, "MappingTokenFactory:can not receive amount zero");
        expendDailyLimit(mappingToken, amount);
        if (guard != address(0)) {
            IERC20(mappingToken).mint(address(this), amount);
            require(IERC20(mappingToken).approve(guard, amount), "MappingTokenFactory:approve token transfer to guard failed");
            IInboundLane.InboundLaneNonce memory inboundLaneNonce = IInboundLane(msg.sender).inboundLaneNonce();
            // todo we should transform this messageId to bridged outboundLane messageId
            uint256 messageId = IInboundLane(msg.sender).encodeMessageKey(inboundLaneNonce.last_delivered_nonce);
            IGuard(guard).deposit(messageId, mappingToken, recipient, amount);
        } else {
            IERC20(mappingToken).mint(recipient, amount);
        }
    }

    /**
     * @notice burn mapping token and unlock remote original token, waiting for the confirm
     * @param bridgedLanePosition the bridged lane position to send the unlock message
     * @param mappingToken the burt mapping token address
     * @param recipient the recipient of the remote unlocked token
     * @param amount the amount of the burn and unlock
     */
    function burnAndRemoteUnlockWaitingConfirm(
        uint32 bridgedLanePosition,
        address mappingToken,
        address recipient,
        uint256 amount
    ) external payable whenNotPaused {
        require(amount > 0, "MappingTokenFactory:can not transfer amount zero");
        address originalToken = mappingToken2OriginalToken[mappingToken];
        require(originalToken != address(0), "MappingTokenFactory:token is not created by factory");
        // Lock the fund in this before message on remote backing chain get dispatched successfully and burn finally
        // If remote backing chain unlock the origin token successfully, then this fund will be burned.
        // Otherwise, this fund will be transfered back to the msg.sender.
        require(IERC20(mappingToken).transferFrom(msg.sender, address(this), amount), "MappingTokenFactory:transfer token failed");

        bytes memory unlockFromRemote = abi.encodeWithSelector(
            IBacking.unlockFromRemote.selector,
            address(this),
            originalToken,
            recipient,
            amount
        );

        uint256 messageId = _sendMessage(bridgedLanePosition, unlockFromRemote);
        unlockRemoteUnconfirmed[messageId] = UnconfirmedInfo(msg.sender, mappingToken, amount);
        emit BurnAndWaitingConfirm(messageId, msg.sender, recipient, mappingToken, amount);
    }

    /**
     * @notice this will be called when the burn and unlock from remote message confirmed
     * @param messageId the message id, is used to identify the unlocked message
     * @param result the result of the remote backing's unlock, if false, the mapping token need to transfer back to the user, otherwise burt
     */
    function on_messages_delivered(
        uint256 messageId,
        bool result
    ) external onlyOutBoundLane {
        UnconfirmedInfo memory info = unlockRemoteUnconfirmed[messageId];
        require(info.amount > 0 && info.sender != address(0) && info.mappingToken != address(0), "MappingTokenFactory:invalid unconfirmed message");
        if (result) {
            IERC20(info.mappingToken).burn(address(this), info.amount);
        } else {
            require(IERC20(info.mappingToken).transfer(info.sender, info.amount), "MappingTokenFactory:transfer back failed");
        }
        delete unlockRemoteUnconfirmed[messageId];
        emit RemoteUnlockConfirmed(messageId, result);
    }
}

