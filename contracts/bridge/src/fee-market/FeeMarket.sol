// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/IFeeMarket.sol";
import "../proxy/Initializable.sol";

contract FeeMarket is Initializable, IFeeMarket {
    // Relayer count
    uint256 public relayerCount;
    // Governance role to decide which outbounds message to relay
    address public setter;
    // Outbounds which message will be relayed by relayers
    mapping(address => uint256) public outbounds;
    // Balance of the relayer including deposit and eared fee
    mapping(address => uint256) public balanceOf;
    // Locked balance of relayer for relay messages
    mapping(address => uint256) public lockedOf;
    // All relayers in fee-market, they are linked one by one and sorted by the relayer fee asc
    mapping(address => address) public relayers;
    // Maker fee of the relayer
    mapping(address => uint256) public feeOf;
    // Message encoded key => Order
    mapping(uint256 => Order) public orderOf;
    // message encoded key => assigned slot => assigned relayer
    mapping(uint256 => mapping(uint256 => OrderExt)) public assignedRelayers;

    // System treasury
    address public immutable VAULT;
    // SlashAmount = CollateralPerOrder * LateTime / SlashTime
    uint32 public immutable slashTime;
    // Time assigned relayer to relay messages
    uint32 public immutable relayTime;
    // Fee market assigned relayers numbers
    uint32 public immutable assignedRelayersNumber;
    // Ratio of two chain's native token price, denominator of ratio is 1_000_000
    uint32 public immutable priceRatio;
    // The collateral relayer need to lock for each order.
    uint256 public immutable collateralPerOrder;

    address private constant SENTINEL_HEAD = address(0x1);
    address private constant SENTINEL_TAIL = address(0x2);

    event Assgigned(uint256 indexed key, uint256 timestamp, uint32 assigned_relayers_number, uint256 collateral);
    event Delist(address indexed prev, address indexed cur);
    event Deposit(address indexed dst, uint wad);
    event Enrol(address indexed prev, address indexed cur, uint fee);
    event Locked(address indexed src, uint wad);
    event Reward(address indexed dst, uint wad);
    event SetOutbound(address indexed out, uint256 flag);
    event Settled(uint256 indexed key, uint timestamp);
    event Slash(address indexed src, uint wad);
    event UnLocked(address indexed src, uint wad);
    event Withdrawal(address indexed src, uint wad);

    struct Order {
        // Assigned time of the order
        uint32 time;
        // Assigned number of relayers
        uint32 number;
        // Assigned collateral of each relayer
        uint256 collateral;
    }

    struct OrderExt {
        // Assigned relayer
        address relayer;
        // Assigned relayer maker fee
        uint256 makerFee;
    }

    modifier onlySetter {
        require(msg.sender == setter, "!auth");
        _;
    }

    modifier onlyOutBound() {
        require(outbounds[msg.sender] == 1, "!outbound");
        _;
    }

    modifier enoughBalance() {
        require(balanceOf[msg.sender] >= collateralPerOrder, "!balance");
        _;
    }

    constructor(
        address _vault,
        uint256 _collateral_perorder,
        uint32 _assigned_relayers_number,
        uint32 _slash_time,
        uint32 _relay_time,
        uint32 _price_rario
    ) {
        require(_assigned_relayers_number > 0, "!0");
        require(_slash_time > 0 && _relay_time > 0, "!0");
        VAULT = _vault;
        collateralPerOrder = _collateral_perorder;
        slashTime = _slash_time;
        relayTime = _relay_time;
        assignedRelayersNumber = _assigned_relayers_number;
        priceRatio = _price_rario;
    }

    function initialize() public initializer {
        __FM_init__(msg.sender);
    }

    function __FM_init__(address _setter) internal onlyInitializing {
        setter = _setter;
        relayers[SENTINEL_HEAD] = SENTINEL_TAIL;
        feeOf[SENTINEL_TAIL] = type(uint256).max;
    }

    receive() external payable {
        deposit();
    }

    function setSetter(address _setter) external onlySetter {
        setter = _setter;
    }

    function setOutbound(address out, uint256 flag) external onlySetter {
        outbounds[out] = flag;
        emit SetOutbound(out, flag);
    }

    // Fetch the real time market fee
    function market_fee() external view override returns (uint fee) {
        address[] memory top_relayers = getTopRelayers();
        address last = top_relayers[top_relayers.length - 1];
        return feeOf[last];
    }

    function totalSupply() external view returns (uint) {
        return address(this).balance;
    }

    function getOrder(uint256 key) external view returns (Order memory, OrderExt[] memory) {
        Order memory order = orderOf[key];
        OrderExt[] memory assigned_relayers = new OrderExt[](order.number);
        for (uint slot = 0; slot < order.number; slot++) {
            assigned_relayers[slot] = assignedRelayers[key][slot];
        }
        return (order, assigned_relayers);
    }

    // Fetch the `count` of order book in fee-market
    // If flag set true, will ignore their balance
    // If flag set false, will ensure their balance is sufficient for lock `CollateralPerOrder`
    function getOrderBook(uint count, bool flag)
        external
        view
        returns (
            uint256,
            address[] memory,
            uint256[] memory,
            uint256 [] memory
        )
    {
        require(count <= relayerCount, "!count");
        address[] memory array1 = new address[](count);
        uint256[] memory array2 = new uint256[](count);
        uint256[] memory array3 = new uint256[](count);
        uint index = 0;
        address cur = relayers[SENTINEL_HEAD];
        while (cur != SENTINEL_TAIL && index < count) {
            if (flag || balanceOf[cur] >= collateralPerOrder) {
                array1[index] = cur;
                array2[index] = feeOf[cur];
                array3[index] = balanceOf[cur];
                index++;
            }
            cur = relayers[cur];
        }
        return (index, array1, array2, array3);
    }

    // Find top lowest maker fee relayers
    function getTopRelayers() public view returns (address[] memory) {
        require(assignedRelayersNumber <= relayerCount, "!count");
        address[] memory array = new address[](assignedRelayersNumber);
        uint index = 0;
        address cur = relayers[SENTINEL_HEAD];
        while (cur != SENTINEL_TAIL && index < assignedRelayersNumber) {
            if (balanceOf[cur] >= collateralPerOrder) {
                array[index] = cur;
                index++;
            }
            cur = relayers[cur];
        }
        require(index == assignedRelayersNumber, "!assigned");
        return array;
    }

    // Fetch the order fee by the encoded message key
    function getOrderFee(uint256 key) public view returns (uint256 fee) {
        uint32 number = orderOf[key].number;
        fee = assignedRelayers[key][number - 1].makerFee;
    }

    function getAssignedRelayer(uint256 key, uint256 slot) public view returns (address) {
        return assignedRelayers[key][slot].relayer;
    }

    function getSlotFee(uint256 key, uint256 slot) public view returns (uint256) {
        return assignedRelayers[key][slot].makerFee;
    }

    function isRelayer(address addr) public view returns (bool) {
        return addr != SENTINEL_HEAD && addr != SENTINEL_TAIL && relayers[addr] != address(0);
    }

    // Deposit native token for collateral to relay message
    // After enroll the relayer and be assigned new message
    // Deposited token will be locked for relay the message
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Withdraw your free/eared balance anytime.
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    // Deposit native token and enroll to be a relayer at fee-market
    function enroll(address prev, uint fee) external payable {
        deposit();
        enrol(prev, fee);
    }

    // Withdraw all balance and remove relayer role at fee-market
    function leave(address prev) public {
        withdraw(balanceOf[msg.sender]);
        delist(prev);
    }

    // Enroll to be a relayer
    // `prev` is the previous relayer
    // `fee` is the maker fee to set, PrevFee <= MakerFee <= NextFee
    function enrol(address prev, uint fee) public enoughBalance {
        address cur = msg.sender;
        address next = relayers[prev];
        require(cur != address(0) && cur != SENTINEL_HEAD && cur != SENTINEL_TAIL && cur != address(this), "!valid");
        // No duplicate relayer allowed.
        require(relayers[cur] == address(0), "!new");
        // Prev relayer must in the list.
        require(next != address(0), "!next");
        // PrevFee <= MakerFee <= NextFee
        require(fee >= feeOf[prev], "!>=");
        require(fee <= feeOf[next], "!<=");
        relayers[cur] = next;
        relayers[prev] = cur;
        feeOf[cur] = fee;
        relayerCount++;
        emit Enrol(prev, cur, fee);
    }

    // Remove the relayer from the fee-market
    function delist(address prev) public {
        _delist(prev, msg.sender);
    }

    // Prune relayers which have not enough collateral
    function prune(address prev, address cur) public {
        if (lockedOf[cur] == 0 && balanceOf[cur] < collateralPerOrder) {
            _delist(prev, cur);
        }
    }

    // Move your position in the fee-market orderbook
    function move(address old_prev, address new_prev, uint new_fee) external {
        delist(old_prev);
        enrol(new_prev, new_fee);
    }

    // Assign new message encoded key to top N relayers in fee-market
    function assign(uint256 key) external override payable onlyOutBound returns (bool) {
        // Select top N relayers
        address[] memory top_relayers = _get_and_prune_top_relayers();
        address last = top_relayers[top_relayers.length - 1];
        require(msg.value == feeOf[last], "!fee");
        for (uint slot = 0; slot < top_relayers.length; slot++) {
            address r = top_relayers[slot];
            require(isRelayer(r), "!relayer");
            _lock(r, collateralPerOrder);
            assignedRelayers[key][slot] = OrderExt(r, feeOf[r]);
        }
        // Record the assigned time
        orderOf[key] = Order(uint32(block.timestamp), assignedRelayersNumber, collateralPerOrder);
        emit Assgigned(key, block.timestamp, assignedRelayersNumber, collateralPerOrder);
        return true;
    }

    // Settle delivered messages and reward/slash relayers
    function settle(DeliveredRelayer[] calldata delivery_relayers, address confirm_relayer) external override onlyOutBound returns (bool) {
        _pay_relayers_rewards(delivery_relayers, confirm_relayer);
        return true;
    }

    function _get_and_prune_top_relayers() private returns (address[] memory) {
        require(assignedRelayersNumber <= relayerCount, "!count");
        address[] memory array = new address[](assignedRelayersNumber);
        uint index = 0;
        address prev = SENTINEL_HEAD;
        address cur = relayers[SENTINEL_HEAD];
        while (cur != SENTINEL_TAIL && index < assignedRelayersNumber) {
            if (balanceOf[cur] >= collateralPerOrder) {
                array[index] = cur;
                index++;
            } else {
                prune(prev, cur);
            }
            prev = cur;
            cur = relayers[cur];
        }
        require(index == assignedRelayersNumber, "!assigned");
        return array;
    }

    function _delist(address prev, address cur) private {
        require(cur != address(0) && cur != SENTINEL_HEAD && cur != SENTINEL_TAIL, "!valid");
        require(relayers[prev] == cur, "!cur");
        relayers[prev] = relayers[cur];
        relayers[cur] = address(0);
        feeOf[cur] = 0;
        relayerCount--;
        emit Delist(prev, cur);
    }

    function _lock(address to, uint wad) private {
        require(balanceOf[to] >= wad, "!lock");
        balanceOf[to] -= wad;
        lockedOf[to] += wad;
        emit Locked(to, wad);
    }

    function _unlock(address to, uint wad) private {
        require(lockedOf[to] >= wad, "!unlock");
        lockedOf[to] -= wad;
        balanceOf[to] += wad;
        emit UnLocked(to, wad);
    }

    function _slash(address src, uint wad) private {
        require(lockedOf[src] >= wad, "!slash");
        lockedOf[src] -= wad;
        emit Slash(src, wad);
    }

    function _reward(address dst, uint wad) private {
        balanceOf[dst] += wad;
        emit Reward(dst, wad);
    }

    // Pay rewards to given relayers, optionally rewarding confirmation relayer.
    function _pay_relayers_rewards(
        DeliveredRelayer[] memory delivery_relayers,
        address confirm_relayer
    ) private {
        uint256 total_confirm_reward = 0;
        uint256 total_vault_reward = 0;
        for (uint256 i = 0; i < delivery_relayers.length; i++) {
            DeliveredRelayer memory entry = delivery_relayers[i];
            uint256 every_delivery_reward = 0;
            for (uint256 key = entry.begin; key <= entry.end; key++) {
                (uint256 delivery_reward, uint256 confirm_reward, uint256 vault_reward) = _settle_order(key);
                every_delivery_reward += delivery_reward;
                total_confirm_reward += confirm_reward;
                total_vault_reward += vault_reward;
                // Clean order
                _clean_order(key);
                emit Settled(key, block.timestamp);
            }
            // Reward every delivery relayer
            _reward(entry.relayer, every_delivery_reward);
        }
        // Reward confirm relayer
        _reward(confirm_relayer, total_confirm_reward);
        // Reward vault
        _reward(VAULT, total_vault_reward);
    }

    function _settle_order(uint256 key) private returns (
        uint256 delivery_reward,
        uint256 confirm_reward,
        uint256 vault_reward
    ) {
        require(orderOf[key].time > 0, "!exist");
        // Get the message fee from the top N relayers
        uint256 message_fee = getOrderFee(key);
        // Get slot index and slot price
        (uint256 slot, uint256 slot_price) = _get_slot_price(key, message_fee);
        // Message surplus = Message Fee - Slot price
        uint256 message_surplus = message_fee - slot_price;
        // A. Slot Offensive Slash
        uint256 slot_offensive_slash = _do_slot_offensive_slash(key, slot);
        // Message Reward = Slot price + Slot Offensive Slash
        uint256 message_reward = slot_price + slot_offensive_slash;
        // B. Slot Duty Reward
        uint256 slot_duty_reward = _do_slot_duty_reward(key, slot, message_surplus);
        // Message Reward -> (delivery_relayer, confirm_relayer)
        (delivery_reward, confirm_reward) = _distribute_fee(message_reward);
        // Message surplus -= Slot Duty Reward
        require(message_surplus >= slot_duty_reward, "!surplus");
        vault_reward = message_surplus - slot_duty_reward;
    }

    function _get_order_status(uint key) private view returns (
        bool is_ontime,
        uint256 diff_time,
        uint256 number,
        uint256 collateral
    ) {
        Order memory order = orderOf[key];
        number = order.number;
        collateral = order.collateral;
        // Diff_time = settle_time - assign_time
        diff_time = block.timestamp - order.time;
        is_ontime = diff_time < order.number * relayTime;
    }

    function _get_slot_price(
        uint256 key,
        uint256 message_fee
    ) private view returns (uint256, uint256) {
        (bool is_ontime, uint diff_time, uint number,) = _get_order_status(key);
        if (is_ontime) {
            for (uint slot = 0; slot < number; slot++) {
                // The message confirmed in the `slot` assign_relayer
                // [slot, slot+1)
                if (slot * relayTime <= diff_time && diff_time < (slot + 1) * relayTime) {
                    uint256 slot_price = getSlotFee(key, slot);
                    return (slot, slot_price);
                }
            }
            assert(false);
        } else {
            return (number, message_fee);
        }
    }

    function _do_slot_offensive_slash(
        uint256 key,
        uint256 slot
    ) private returns (uint256 slot_offensive_slash) {
        (bool is_ontime, uint diff_time, uint number, uint collateral) = _get_order_status(key);
        if (is_ontime) {
            for (uint _slot = 0; _slot < number; _slot++) {
                address assign_relayer = getAssignedRelayer(key, _slot);
                if (_slot < slot) {
                    uint256 slash_fee = collateral * 2 / 10;
                    _slash(assign_relayer, slash_fee);
                    _unlock(assign_relayer, (collateral - slash_fee));
                    slot_offensive_slash += slash_fee;
                } else {
                    _unlock(assign_relayer, collateral);
                }
            }
        } else {
            uint256 slash_fee = collateral * 2 / 10;
            uint256 remaining = collateral - slash_fee;
            uint256 late_time = diff_time - number * relayTime;
            slash_fee += late_time >= slashTime ? remaining : (remaining * late_time / slashTime);
            for (uint _slot = 0; _slot < number; _slot++) {
                address assign_relayer = getAssignedRelayer(key, _slot);
                _slash(assign_relayer, slash_fee);
                _unlock(assign_relayer, (collateral - slash_fee));
                slot_offensive_slash += slash_fee;
            }
        }
    }

    function _do_slot_duty_reward(
        uint256 key,
        uint256 slot,
        uint256 message_surplus
    ) private returns (uint256 slot_duty_reward) {
        (bool is_ontime, , uint number,) = _get_order_status(key);
        uint _total_reward = message_surplus * 2 / 10;
        if (is_ontime && _total_reward > 0) {
            require(number > slot, "!slot");
            uint _per_reward = _total_reward / (number - slot);
            for (uint _slot = 0; _slot < number; _slot++) {
                if (_slot >= slot) {
                    address assign_relayer = getAssignedRelayer(key, _slot);
                    _reward(assign_relayer, _per_reward);
                    slot_duty_reward += _per_reward;
                }
            }
        } else {
            return 0;
        }
    }

    function _clean_order(uint256 key) private {
        (, , uint number,) = _get_order_status(key);
        for (uint _slot = 0; _slot < number; _slot++) {
            delete assignedRelayers[key][_slot];
        }
        delete orderOf[key];
    }

    function _distribute_fee(uint256 fee) private view returns (
        uint256 delivery_reward,
        uint256 confirm_reward
    ) {
        // fee * priceRatio / 1_000_000 => delivery relayer
        delivery_reward = fee * priceRatio / 1_000_000;
        // remaining fee => confirm relayer
        confirm_reward = fee - delivery_reward;
    }
}
