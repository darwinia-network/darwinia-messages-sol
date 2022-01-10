// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/utils/math/SafeMath.sol";
import "@darwinia/contracts-utils/contracts/Pausable.sol";
import "./GuardRegistry.sol";
import "../interfaces/IERC20.sol";

contract Guard is GuardRegistry, Pausable {
    using SafeMath for uint256;

    struct DepositInfo {
        address token;
        address recipient;
        uint256 amount;
        uint256 timestamp;
    }

    mapping(uint256 => DepositInfo) depositors;

    uint256 public maxUnclaimableTime;
    address public depositor;
    address public operator;

    event TokenDeposit(uint256 id, address token, address recipient, uint256 amount);
    event TokenClaimed(uint256 id);

    constructor(address[] memory _guards, uint256 _threshold, uint256 _maxUnclaimableTime, address _depositor) public {
        maxUnclaimableTime = _maxUnclaimableTime;
        depositor = _depositor;
        operator = msg.sender;
        initialize(_guards, _threshold);
    }

    modifier onlyDepositor() {
        require(msg.sender == depositor, "Guard: Invalid depositor");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Guard: Invalid operator");
        _;
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function pause() external onlyOperator {
        _pause();
    }

    function setOperator(address newOperator, bytes[] memory signatures) external {
        verifyGuardSignatures(msg.sig, abi.encode(newOperator), signatures);
        operator = newOperator;
    }

    /**
      * @dev deposit token to guard, waiting to claim, only allowed depositor
      * @param id the id of the operation, should be siged later by guards
      * @param token the erc20 token address
      * @param recipient the recipient of the token
      * @param amount the amount of the token
      */
    function deposit(uint256 id, address token, address recipient, uint256 amount) public onlyDepositor whenNotPaused {
        require(depositors[id].amount == 0, "Guard: the asset exist");
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "AssetStore: deposit transfer failed");
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        require(balanceBefore.add(amount) == balanceAfter, "Guard:Transfer amount is invalid");

        depositors[id] = DepositInfo(token, recipient, amount, block.timestamp);
        emit TokenDeposit(id, token, recipient, amount);
    }

    function claimById(uint256 id) internal whenNotPaused {
        DepositInfo memory info = depositors[id];
        require(info.amount > 0, "Guard: Invalid id to claim");
        require(IERC20(info.token).transfer(info.recipient, info.amount), "Guard: claim token failed");
        delete depositors[id];
        emit TokenClaimed(id);
    }

    /**
      * @dev claim the tokens in the contract saved by deposit, this acquire signatures from guards
      * @param ids the array of the id to be claimed
      * @param signatures the signatures of the guards which to claim tokens.
      */
    function claim(uint256[] memory ids, bytes[] memory signatures) public {
        verifyGuardSignatures(msg.sig, abi.encode(ids), signatures);
        for (uint idx = 0; idx < ids.length; idx++) {
            uint256 id = ids[idx];
            DepositInfo memory info = depositors[id];
            if (info.amount > 0) {
                claimById(id);
            }
        }
    }

    /**
      * @dev claim the tokens without signatures, this only allowed when timeout
      * @param id the id to be claimed
      */
    function claimByTimeout(uint256 id) public {
        DepositInfo memory info = depositors[id];
        require(info.timestamp < block.timestamp && block.timestamp - info.timestamp > maxUnclaimableTime, "Guard: claim at invalid time");
        claimById(id);
    }
}

