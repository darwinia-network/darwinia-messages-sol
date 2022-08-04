// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/IFeeMarket.sol";

contract SimpleFeeMarket is IFeeMarket {
    event SetOutbound(address indexed out, uint256 flag);
    event Slash(address indexed src, uint wad);
    event Reward(address indexed dst, uint wad);
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);
    event Locked(address indexed src, uint wad);
    event UnLocked(address indexed src, uint wad);
    event Enrol(address indexed prev, address indexed cur, uint fee);
    event Delist(address indexed prev, address indexed cur);
    event Assgigned(uint256 indexed key, uint256 timestamp, address relayer, uint256 collateral, uint256 fee);
    event Settled(uint256 indexed key, uint timestamp);

    address private constant SENTINEL_HEAD = address(0x1);
    address private constant SENTINEL_TAIL = address(0x2);

    // SlashAmount = CollateralPerOrder * LateTime / SlashTime
    uint32 public slashTime;
    // Time assigned relayer to relay messages
    uint32 public relayTime;
    // Ratio of two chain's native token price, denominator of ratio is 1_000_000
    uint32 public priceRatio;
    // The collateral relayer need to lock for each order.
    uint256 public collateralPerOrder;
    // Governance role to decide which outbounds message to relay
    address public setter;
    // All outbounds that message will be relayed by relayers
    mapping(address => uint256) public outbounds;
    // Balance of the relayer including deposit and eared fee
    mapping(address => uint256) public balanceOf;
    // Locked balance of relayer for relay messages
    mapping(address => uint256) public lockedOf;
    // All relayers in fee-market, they are linked one by one and sorted by the relayer fee asc
    mapping(address => address) public relayers;
    // Relayer count
    uint256 public relayerCount;
    // Maker fee of the relayer
    mapping(address => uint256) public feeOf;

    struct Order {
        // Assigned time
        uint32 assignedTime;
        // Assigned relayer
        address assignedRelayer;
        // Assigned collateral
        uint256 collateral;
        // Assigned relayer maker fee
        uint256 makerFee;
    }
    // Message encoded key => Order
    mapping(uint256 => Order) public orderOf;

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
        uint256 _collateral_perorder,
        uint32 _slash_time,
        uint32 _relay_time,
        uint32 _price_rario
    ) {
        require(_slash_time > 0 && _relay_time > 0, "!0");
        setter = msg.sender;
        collateralPerOrder = _collateral_perorder;
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

    function setParameters(
        uint32 slash_time,
        uint32 relay_time,
        uint32 price_ratio,
        uint256 collateral_perorder
    ) external onlySetter {
        require(slash_time > 0 && relay_time > 0, "!0");
        slashTime = slash_time;
        relayTime = relay_time;
        priceRatio = price_ratio;
        collateralPerOrder = collateral_perorder;
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    // Fetch the `count` of order book in fee-market
    // If flag set true, will ignore their balance
    // If flag set false, will ensure they have enough balance
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

    // Find top lowest maker fee relayer
    function getTopRelayer() public view returns (address top) {
        address cur = relayers[SENTINEL_HEAD];
        while (cur != SENTINEL_TAIL) {
            if (balanceOf[cur] >= collateralPerOrder) {
                top = cur;
                break;
            }
            cur = relayers[cur];
        }
        require(top != address(0), "!top");
    }

    function isRelayer(address addr) public view returns (bool) {
        return addr != SENTINEL_HEAD && addr != SENTINEL_TAIL && relayers[addr] != address(0);
    }

    // Fetch the real time maket maker fee
    // Revert `!top` when there is not enroll relayer in the fee-market
    function market_fee() external view override returns (uint fee) {
        address top_relayer = getTopRelayer();
        return feeOf[top_relayer];
    }

    // Deposit native token as collateral to enrol relayer
    // Once the relayer is assigned to relay a new message
    // the deposited token of assigned relayer  will be locked
    // as collateral to relay the message, After the assigned message is settled
    // the locked token will be free
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Withdraw your free(including eared) balance anytime.
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    // Deposit native token and enrol to be a relayer
    function enroll(address prev, uint fee) public payable {
        deposit();
        enrol(prev, fee);
    }

    // Withdraw all balance and delist relayer role
    function leave(address prev) public {
        withdraw(balanceOf[msg.sender]);
        delist(prev);
    }

    // Enrol to be a relayer
    // `prev` is the previous relayer
    // `fee` is the maker fee to set, PrevFee <= CurFee <= NextFee
    function enrol(address prev, uint fee) public enoughBalance {
        address cur = msg.sender;
        address next = relayers[prev];
        require(
            cur != address(0) &&
            cur != SENTINEL_HEAD &&
            cur != SENTINEL_TAIL,
            "!valid"
        );
        // No duplicate relayer allowed.
        require(relayers[cur] == address(0), "!new");
        // Next relayer must in the list.
        require(next != address(0), "!next");
        // PrevFee <= CurFee <= NextFee
        require(feeOf[prev] <= fee && fee <= feeOf[next], "!fee");
        relayers[cur] = next;
        relayers[prev] = cur;
        feeOf[cur] = fee;
        relayerCount++;
        emit Enrol(prev, cur, fee);
    }

    // Delist the relayer from the fee-market
    function delist(address prev) public {
        _delist(prev, msg.sender);
    }

    function _delist(address prev, address cur) private {
        require(
            cur != address(0) &&
            cur != SENTINEL_HEAD &&
            cur != SENTINEL_TAIL,
            "!valid"
        );
        require(relayers[prev] == cur, "!cur");
        relayers[prev] = relayers[cur];
        relayers[cur] = address(0);
        feeOf[cur] = 0;
        relayerCount--;
        emit Delist(prev, cur);
    }

    // Prune relayers which have not enough collateral
    function prune(address prev, address cur) public {
        if (lockedOf[cur] == 0 && balanceOf[cur] < collateralPerOrder) {
            _delist(prev, cur);
        }
    }

    // Move your position in the fee-market orderbook
    function move(address old_prev, address new_prev, uint new_fee) public {
        delist(old_prev);
        enrol(new_prev, new_fee);
    }

    // Assign new message with encoded key to top relayer in fee-market
    function assign(uint256 key) public override payable onlyOutBound returns (bool) {
        // Fetch top relayer
        address top_relayer = _get_and_prune_top_relayer();
        require(isRelayer(top_relayer), "!relayer");
        uint256 fee = feeOf[top_relayer];
        require(msg.value == fee, "!fee");
        uint256 _collateral = collateralPerOrder;
        _lock(top_relayer, _collateral);
        // record the assigned time
        uint32 assign_time = uint32(block.timestamp);
        orderOf[key] = Order(assign_time, top_relayer, _collateral, fee);
        emit Assgigned(key, assign_time, top_relayer, _collateral, fee);
        return true;
    }

    // Settle delivered messages and reward/slash relayers
    function settle(
        DeliveredRelayer[] calldata delivery_relayers,
        address confirm_relayer
    ) external override onlyOutBound returns (bool) {
        _pay_relayers_rewards(delivery_relayers, confirm_relayer);
        return true;
    }

    function _get_and_prune_top_relayer() private returns (address top) {
        address prev = SENTINEL_HEAD;
        address cur = relayers[SENTINEL_HEAD];
        while (cur != SENTINEL_TAIL) {
            if (balanceOf[cur] >= collateralPerOrder) {
                top = cur;
                break;
            } else {
                prune(prev, cur);
                prev = cur;
                cur = relayers[cur];
            }
        }
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
    function _pay_relayers_rewards(DeliveredRelayer[] memory delivery_relayers, address confirm_relayer) private {
        uint256 total_confirm_reward = 0;
        for (uint256 i = 0; i < delivery_relayers.length; i++) {
            DeliveredRelayer memory entry = delivery_relayers[i];
            uint256 every_delivery_reward = 0;
            for (uint256 key = entry.begin; key <= entry.end; key++) {
                uint256 assigned_time = orderOf[key].assignedTime;
                require(assigned_time > 0, "!exist");
                require(block.timestamp >= assigned_time, "!time");
                // diff_time = settle_time - assign_time
                uint256 diff_time = block.timestamp - orderOf[key].assignedTime;
                // on time
                // [0, slot * 1)
                if (diff_time < relayTime) {
                    // Reward and unlock each assign_relayer
                    (uint256 delivery_reward, uint256 confirm_reward) = _reward_and_unlock_ontime(key,  entry.relayer, confirm_relayer);
                    every_delivery_reward += delivery_reward;
                    total_confirm_reward += confirm_reward;
                // too late
                // [slot * 1, +∞)
                } else {
                    // Slash and unlock each assign_relayer
                    uint256 late_time = diff_time - relayTime;
                    (uint256 delivery_reward, uint256 confirm_reward) = _slash_and_unlock_late(key, late_time);
                    every_delivery_reward += delivery_reward;
                    total_confirm_reward += confirm_reward;
                }
                delete orderOf[key];
                emit Settled(key, block.timestamp);
            }
            // Reward every delivery relayer
            _reward(entry.relayer, every_delivery_reward);
        }
        // Reward confirm relayer
        _reward(confirm_relayer, total_confirm_reward);
    }

    function _reward_and_unlock_ontime(
        uint256 key,
        address delivery_relayer,
        address confirm_relayer
    ) private returns (uint256 delivery_reward, uint256 confirm_reward) {
        Order memory order = orderOf[key];
        address assign_relayer = order.assignedRelayer;
        // The message delivery in the `slot` assign_relayer
        (delivery_reward, confirm_reward) = _distribute_ontime(order.makerFee, assign_relayer, delivery_relayer, confirm_relayer);
        _unlock(assign_relayer, order.collateral);
    }

    function _slash_and_unlock_late(uint256 key, uint256 late_time) private returns (uint256 delivery_reward, uint256 confirm_reward) {
        Order memory order = orderOf[key];
        uint256 message_fee = order.makerFee;
        uint256 collateral = order.collateral;
        // Slash fee is linear incremental, and the slop is `late_time / SlashTime`
        uint256 slash_fee = late_time >= slashTime ? collateral : (collateral * late_time / slashTime);
        address assign_relayer = order.assignedRelayer;
        _slash(assign_relayer, slash_fee);
        _unlock(assign_relayer, (collateral - slash_fee));
        // Reward_fee = message_fee + slash_fee
        (delivery_reward, confirm_reward) = _distribute_fee(message_fee + slash_fee);
    }

    function _distribute_ontime(
        uint256 message_fee,
        address assign_relayer,
        address delivery_relayer,
        address confirm_relayer
    ) private returns (uint256 delivery_reward, uint256 confirm_reward) {
        if (message_fee > 0) {
            // 60% * base fee => assigned_relayers_rewards
            uint256 assign_reward = message_fee * 60 / 100;
            // 40% * base fee => other relayer
            uint256 other_reward = message_fee - assign_reward;
            (delivery_reward, confirm_reward) = _distribute_fee(other_reward);
            // If assign_relayer == delivery_relayer, we give the reward to delivery_relayer
            if (assign_relayer == delivery_relayer) {
                delivery_reward += assign_reward;
            // If assign_relayer == confirm_relayer, we give the reward to confirm_relayer
            } else if (assign_relayer == confirm_relayer) {
                confirm_reward += assign_reward;
            // Both not, we reward the assign_relayer directlly
            } else {
                _reward(assign_relayer, assign_reward);
            }
        }
    }

    function _distribute_fee(uint256 fee) private view returns (uint256 delivery_reward, uint256 confirm_reward) {
        // fee * priceRatio / 1_000_000 => delivery relayer
        delivery_reward = fee * priceRatio / 1_000_000;
        // remaining fee => confirm relayer
        confirm_reward = fee - delivery_reward;
    }
}
