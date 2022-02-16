// SPDX-License-Identifier: MIT
// This is the Issuing Module(Mapping-token-factory) of the ethereum like bridge.
// We trust the inboundLane/outboundLane when we add them to the module.
// It means that each message from the inboundLane is verified correct and truthly from the sourceAccount.
// Only we need is to verify the sourceAccount is expected. And we add it to the Filter.
pragma solidity ^0.8.10;

import "../interfaces/IMessageCommitment.sol";
import "../interfaces/IOutboundLane.sol";
import "../../utils/DailyLimit.sol";
import "../interfaces/IBacking.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IGuard.sol";
import "../interfaces/IInboundLane.sol";
import "../interfaces/IMappingTokenFactory.sol";
import "./MappingTokenFactory.sol";

contract FungibleMappingTokenFactory is DailyLimit, IMappingTokenFactory, MappingTokenFactory {
    struct UnconfirmedInfo {
        address sender;
        address mappingToken;
        uint256 amount;
    }
    // guard
    address public guard;
    mapping(uint256 => UnconfirmedInfo) public unlockRemoteUnconfirmed;

    event IssuingERC20Created(address backingAddress, address originalToken, address mappingToken);
    event BurnAndWaitingConfirm(uint256 messageId, address sender, address recipient, address token, uint256 amount);
    event RemoteUnlockConfirmed(uint256 messageId, bool result);

    receive() external payable {
    }

    function updateGuard(address newGuard) external onlyOwner {
        guard = newGuard;
    }

    function changeDailyLimit(address mappingToken, uint amount) public onlyOwner  {
        _changeDailyLimit(mappingToken, amount);
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
    ) public onlyInBoundLane(backingAddress) whenNotPaused returns (address mappingToken) {
        require(tokenType == 0 || tokenType == 1, "MappingTokenFactory:token type cannot mapping to erc20 token");
        // (bridgeChainId, backingAddress, originalToken) pack a unique new contract salt
        uint32 bridgedChainPosition = IMessageCommitment(msg.sender).bridgedChainPosition();
        bytes32 salt = keccak256(abi.encodePacked(bridgedChainPosition, backingAddress, originalToken));
        require(salt2MappingToken[salt] == address(0), "MappingTokenFactory:contract has been deployed");
        mappingToken = deploy(salt, tokenType);
        IMappingToken(mappingToken).initialize(
            string(abi.encodePacked(name, "[", bridgedChainName, ">")),
            string(abi.encodePacked("x", symbol)),
            decimals);

        // save the mapping tokens in an array so it can be listed
        allMappingTokens.push(mappingToken);
        // map the originToken to mappingInfo
        salt2MappingToken[salt] = mappingToken;
        // map the mappingToken to origin info
        mappingToken2OriginalInfo[mappingToken] = OriginalInfo(bridgedChainPosition, tokenType, backingAddress, originalToken);
        emit IssuingERC20Created(backingAddress, originalToken, mappingToken);
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
    ) public onlyInBoundLane(backingAddress) whenNotPaused {
        uint32 bridgedChainPosition = IMessageCommitment(msg.sender).bridgedChainPosition();
        address mappingToken = getMappingToken(bridgedChainPosition, backingAddress, originalToken);
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
        OriginalInfo memory info = mappingToken2OriginalInfo[mappingToken];
        require(info.originalToken != address(0), "MappingTokenFactory:token is not created by factory");
        // Lock the fund in this before message on remote backing chain get dispatched successfully and burn finally
        // If remote backing chain unlock the origin token successfully, then this fund will be burned.
        // Otherwise, this fund will be transfered back to the msg.sender.
        require(IERC20(mappingToken).transferFrom(msg.sender, address(this), amount), "MappingTokenFactory:transfer token failed");

        uint256 outBoundId = encodeBridgedBoundId(info.bridgedChainPosition, bridgedLanePosition);
        address outboundLane = outboundLanes[outBoundId];
        require(outboundLane != address(0), "MappingTokenFactory:the outbound lane is not exist");
        bytes memory unlockFromRemote = abi.encodeWithSelector(
            IBacking.unlockFromRemote.selector,
            address(this),
            info.originalToken,
            recipient,
            amount
        );
        uint256 fee = IFeeMarket(feeMarket).market_fee();
        require(msg.value >= fee, "MappingTokenFactory:not enough fee to pay");
        uint256 messageId = IOutboundLane(outboundLane).send_message{value: fee}(info.backingAddress, unlockFromRemote);
        unlockRemoteUnconfirmed[messageId] = UnconfirmedInfo(msg.sender, mappingToken, amount);
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
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

