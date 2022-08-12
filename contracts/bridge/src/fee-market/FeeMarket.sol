// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/IFeeMarket.sol";

contract FeeMarket is IFeeMarket {
    event SetOutbound(address indexed out, uint256 flag);
    event Slash(address indexed src, uint wad);
    event Reward(address indexed dst, uint wad);
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);
    event Locked(address indexed src, uint wad);
    event UnLocked(address indexed src, uint wad);
    event Enrol(address indexed prev, address indexed cur, uint fee);
    event Delist(address indexed prev, address indexed cur);
    event Assgigned(uint256 indexed key, uint256 timestamp, uint32 assigned_relayers_number, uint256 collateral);
    event Settled(uint256 indexed key, uint timestamp);

    address private constant SENTINEL_HEAD = address(0x1);
    address private constant SENTINEL_TAIL = address(0x2);
    // System treasury
    address public immutable VAULT;

    // SlashAmount = CollateralPerOrder * LateTime / SlashTime
    uint32 public slashTime;
    // Time assigned relayer to relay messages
    uint32 public relayTime;
    // Fee market assigned relayers numbers
    uint32 public assignedRelayersNumber;
    // Ratio of two chain's native token price, denominator of ratio is 1_000_000
    uint32 public priceRatio;
    // The collateral relayer need to lock for each order.
    uint256 public collateralPerOrder;
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
    // relayer count
    uint256 public relayerCount;
    // Maker fee of the relayer
    mapping(address => uint256) public feeOf;

    struct Order {
        // Assigned time of the order
        uint32 assignedTime;
        // Assigned number of relayers
        uint32 assignedRelayersNumber;
        // Assigned collateral of each relayer
        uint256 collateral;
    }
    // message_encoded_key => Order
    mapping(uint256 => Order) public orderOf;
    struct OrderExt {
        // assigned_relayer
        address assignedRelayer;
        // assigned_relayer_maker_fee
        uint256 makerFee;
    }
    // message_encoded_key => assigned_slot => assigned_relayer
    mapping(uint256 => mapping(uint256 => OrderExt)) public assignedRelayers;

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
        setter = msg.sender;
        VAULT = _vault;
        collateralPerOrder = _collateral_perorder;
        assignedRelayersNumber = _assigned_relayers_number;
        slashTime = _slash_time;
        relayTime = _relay_time;
        priceRatio = _price_rario;
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

    function setParaTime(uint32 slash_time, uint32 relay_time, uint32 price_ratio) external onlySetter {
        require(slash_time > 0 && relay_time > 0, "!0");
        slashTime = slash_time;
        relayTime = relay_time;
        priceRatio = price_ratio;
    }

    function setParaRelay(uint32 assigned_relayers_number, uint256 collateral_perorder) external onlySetter {
        require(assigned_relayers_number > 0, "!0");
        assignedRelayersNumber = assigned_relayers_number;
        collateralPerOrder = collateral_perorder;
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    // fetch the `count` of order book in fee-market
    // if flag set true, will ignore their balance
    // if flag set false, will ensure their balance is sufficient for lock `CollateralPerOrder`
    function getOrderBook(uint count, bool flag) external view returns (uint256, address[] memory, uint256[] memory, uint256 [] memory) {
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

    // find top lowest maker fee relayers
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

    // fetch the order fee by the encoded message key
    function getOrderFee(uint256 key) public view returns (uint256 fee) {
        uint32 number = orderOf[key].assignedRelayersNumber;
        fee = assignedRelayers[key][number - 1].makerFee;
    }

    function getAssignedRelayer(uint256 key, uint256 slot) public view returns (address) {
        return assignedRelayers[key][slot].assignedRelayer;
    }

    function getSlotFee(uint256 key, uint256 slot) public view returns (uint256) {
        return assignedRelayers[key][slot].makerFee;
    }

    function getOrder(uint256 key) external view returns (Order memory, OrderExt[] memory) {
        Order memory order = orderOf[key];
        OrderExt[] memory assigned_relayers = new OrderExt[](order.assignedRelayersNumber);
        for (uint slot = 0; slot < order.assignedRelayersNumber; slot++) {
            assigned_relayers[slot] = assignedRelayers[key][slot];
        }
        return (order, assigned_relayers);
    }

    function isRelayer(address addr) public view returns (bool) {
        return addr != SENTINEL_HEAD && addr != SENTINEL_TAIL && relayers[addr] != address(0);
    }

    // deposit native token for collateral to relay message
    // after enroll the relayer and be assigned new message
    // deposited token will be locked for relay the message
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // withdraw your free/eared balance anytime.
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    // fetch the real time market fee
    function market_fee() external view override returns (uint fee) {
        address[] memory top_relayers = getTopRelayers();
        address last = top_relayers[top_relayers.length - 1];
        return feeOf[last];
    }

    // deposit native token and enroll to be a relayer at fee-market
    function enroll(address prev, uint fee) public payable {
        deposit();
        enrol(prev, fee);
    }

    // withdraw all balance and remove relayer role at fee-market
    function leave(address prev) public {
        withdraw(balanceOf[msg.sender]);
        delist(prev);
    }

    // enroll to be a relayer
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

    // remove the relayer from the fee-market
    function delist(address prev) public {
        _delist(prev, msg.sender);
    }

    // prune relayers which have not enough collateral
    function prune(address prev, address cur) public {
        if (lockedOf[cur] == 0 && balanceOf[cur] < collateralPerOrder) {
            _delist(prev, cur);
        }
    }

    // move your position in the fee-market orderbook
    function move(address old_prev, address new_prev, uint new_fee) public {
        delist(old_prev);
        enrol(new_prev, new_fee);
    }

    // Assign new message encoded key to top N relayers in fee-market
    function assign(uint256 key) public override payable onlyOutBound returns (bool) {
        //select top N relayers
        address[] memory top_relayers = _get_and_prune_top_relayers();
        address last = top_relayers[top_relayers.length - 1];
        require(msg.value == feeOf[last], "!fee");
        for (uint slot = 0; slot < top_relayers.length; slot++) {
            address r = top_relayers[slot];
            require(isRelayer(r), "!relayer");
            _lock(r, collateralPerOrder);
            assignedRelayers[key][slot] = OrderExt(r, feeOf[r]);
        }
        // record the assigned time
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

    /// Pay rewards to given relayers, optionally rewarding confirmation relayer.
    function _pay_relayers_rewards(DeliveredRelayer[] memory delivery_relayers, address confirm_relayer) private {
        uint256 total_confirm_reward = 0;
        uint256 total_vault_reward = 0;
        for (uint256 i = 0; i < delivery_relayers.length; i++) {
            DeliveredRelayer memory entry = delivery_relayers[i];
            uint256 every_delivery_reward = 0;
            for (uint256 key = entry.begin; key <= entry.end; key++) {
                (uint256 delivery_reward, uint256 confirm_reward, uint256 vault_reward) = _settle_order(key, entry.relayer, confirm_relayer);
                every_delivery_reward += delivery_reward;
                total_confirm_reward += confirm_reward;
                total_vault_reward += vault_reward;
                // clean order
                _clean_order(key);
                emit Settled(key, block.timestamp);
            }
            // reward every delivery relayer
            _reward(entry.relayer, every_delivery_reward);
        }
        // reward confirm relayer
        _reward(confirm_relayer, total_confirm_reward);
        // reward vault
        _reward(VAULT, total_vault_reward);
    }

    function _settle_order(
        uint256 key,
        address delivery_relayer,
        address confirm_relayer
    ) private returns (
        uint256 delivery_reward,
        uint256 confirm_reward,
        uint256 vault_reward
    ) {
        Order memory order = orderOf[key];
        require(orderOf[key].assignedTime > 0, "!exist");
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

    function _get_order_status(
        uint key
    ) private view returns (
        bool is_ontime,
        uint256 diff_time,
        uint256 number,
        uint256 collateral
    ) {
        Order memory order = orderOf[key];
        number = order.assignedRelayersNumber;
        collateral = order.collateral;
        // Diff_time = settle_time - assign_time
        diff_time = block.timestamp - order.assignedTime;
        is_ontime = diff_time < order.assignedRelayersNumber * relayTime;
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

    function _distribute_fee(uint256 fee) private view returns (uint256 delivery_reward, uint256 confirm_reward) {
        // fee * priceRatio / 1_000_000 => delivery relayer
        delivery_reward = fee * priceRatio / 1_000_000;
        // remaining fee => confirm relayer
        confirm_reward = fee - delivery_reward;
    }
}
