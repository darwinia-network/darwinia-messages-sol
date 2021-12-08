pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../../interfaces/IFeeMarket.sol";

contract FeeMarket is IFeeMarket {
    event SetOwner(address indexed o, address indexed n);
    event SetOutbound(address indexed out, uint256 flag);
    event SetParaTime(uint32 slash_time, uint32 relay_time);
    event SetParaRelay(uint32 assigned_relayers_number, uint256 collateral);
    event Slash(address indexed src, uint wad);
    event Reward(address indexed dst, uint wad);
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);
    event Locked(address indexed src, uint wad);
    event UnLocked(address indexed src, uint wad);
    event AddRelayer(address indexed prev, address indexed cur, uint fee);
    event RemoveRelayer(address indexed prev, address indexed cur);
    event OrderAssgigned(uint256 indexed key, uint256 timestamp, uint32 assigned_relayers_number, uint256 collateral);
    event OrderSettled(uint256 indexed key, uint timestamp);

    address private constant SENTINEL_HEAD = address(0x1);
    address private constant SENTINEL_TAIL = address(0x2);
    // System treasury
    address public immutable VAULT;

    // SlashAmount = CollateralPerorder * LateTime / SlashTime
    uint32 public slashTime;
    // Time assigned relayer to relay messages
    uint32 public relayTime;
    // Fee market assigned relayers numbers
    uint32 public assignedRelayersNumber;
    // The collateral relayer need to lock for each order.
    uint256 public collateralPerorder;
    // Governance role to decide which outbounds message to relay
    address public owner;
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
    // message_encoded_key => assigned_slot => assigned_relayer
    mapping(uint256 => mapping(uint256 => address)) public assignedRelayers;

    modifier onlyOwner {
        require(msg.sender == owner, "!owner");
        _;
    }

    modifier onlyOutBound() {
        require(outbounds[msg.sender] == 1, "!outbound");
        _;
    }

    modifier enoughBalance() {
        require(balanceOf[msg.sender] >= collateralPerorder, "!balance");
        _;
    }

    constructor(
        address _vault,
        uint256 _collateral_perorder,
        uint32 _assigned_relayers_number,
        uint32 _slash_time,
        uint32 _relay_time
    ) public {
        require(_assigned_relayers_number > 0, "!0");
        require(_slash_time > 0 && _relay_time > 0, "!0");
        owner = msg.sender;
        VAULT = _vault;
        collateralPerorder = _collateral_perorder;
        assignedRelayersNumber = _assigned_relayers_number;
        slashTime = _slash_time;
        relayTime = _relay_time;
        relayers[SENTINEL_HEAD] = SENTINEL_TAIL;
        feeOf[SENTINEL_TAIL] = uint256(-1);
    }

    receive() external payable {
        deposit();
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit SetOwner(owner, _owner);
    }

    function setOutbound(address out, uint256 flag) external onlyOwner {
        outbounds[out] = flag;
        emit SetOutbound(out, flag);
    }

    function setParaTime(uint32 slash_time, uint32 relay_time) external onlyOwner {
        require(slash_time > 0 && relay_time > 0, "!0");
        slashTime = slash_time;
        relayTime = relay_time;
        emit SetParaTime(slash_time, relay_time);
    }

    function setParaRelay(uint32 assigned_relayers_number, uint256 collateral_perorder) external onlyOwner {
        require(assigned_relayers_number > 0, "!0");
        assignedRelayersNumber = assigned_relayers_number;
        collateralPerorder = collateral_perorder;
        emit SetParaRelay(assigned_relayers_number, collateral_perorder);
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
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    // fetch the `count` of order book in fee-market
    // if flag set true, will ignore their balance
    // if flag set false, will ensure their balance is sufficient for lock `CollateralPerorder`
    function getOrderBook(uint count, bool flag) external view returns (uint256, address[] memory, uint256[] memory, uint256 [] memory) {
        require(count <= relayerCount, "!count");
        address[] memory array1 = new address[](count);
        uint256[] memory array2 = new uint256[](count);
        uint256[] memory array3 = new uint256[](count);
        uint index = 0;
        address cur = relayers[SENTINEL_HEAD];
        while (cur != SENTINEL_TAIL) {
            if (flag || balanceOf[cur] >= collateralPerorder) {
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
            if (balanceOf[cur] >= collateralPerorder) {
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
        address last = assignedRelayers[key][number - 1];
        fee = feeOf[last];
    }

    function isRelayer(address addr) public view returns (bool) {
        return addr != SENTINEL_HEAD && addr != SENTINEL_TAIL && relayers[addr] != address(0);
    }

    // fetch the real time maket fee
    function market_fee() external view override returns (uint fee) {
        address[] memory top_relayers = getTopRelayers();
        address last = top_relayers[top_relayers.length - 1];
        return feeOf[last];
    }

    // deposit native token and enroll to be a relayer at fee-market
    function enroll(address prev, uint fee) public payable {
        deposit();
        addRelayer(prev, fee);
    }

    // withdraw all balance and remove relayer role at fee-market
    function unenroll(address prev) public {
        withdraw(balanceOf[msg.sender]);
        removeRelayer(prev);
    }

    // enroll to be a relayer
    // `prev` is the previous relayer
    // `fee` is the maker fee to set, PrevFee <= MakerFee <= NextFee
    function addRelayer(address prev, uint fee) public enoughBalance {
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
        emit AddRelayer(prev, cur, fee);
    }

    // remove the relayer from the fee-market
    function removeRelayer(address prev) public {
        _remove_relayer(prev, msg.sender);
    }

    function pruneRelayer(address prev, address cur) public {
        if (lockedOf[cur] == 0 && balanceOf[cur] < collateralPerorder) {
            _remove_relayer(prev, cur);
        }
    }

    // move your position in the fee-market orderbook
    function moveRelayer(address old_prev, address new_prev, uint new_fee) public {
        removeRelayer(old_prev);
        addRelayer(new_prev, new_fee);
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
            _lock(r, collateralPerorder);
            assignedRelayers[key][slot] = r;
        }
        // record the assigned time
        orderOf[key] = Order(uint32(block.timestamp), assignedRelayersNumber, collateralPerorder);
        emit OrderAssgigned(key, block.timestamp, assignedRelayersNumber, collateralPerorder);
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
            if (balanceOf[cur] >= collateralPerorder) {
                array[index] = cur;
                index++;
            } else {
                pruneRelayer(prev, cur);
            }
            prev = cur;
            cur = relayers[cur];
        }
        require(index == assignedRelayersNumber, "!assigned");
        return array;
    }

    function _remove_relayer(address prev, address cur) private {
        require(cur != address(0) && cur != SENTINEL_HEAD && cur != SENTINEL_TAIL, "!valid");
        require(relayers[prev] == cur, "!cur");
        require(lockedOf[cur] == 0, "!locked");
        relayers[prev] = relayers[cur];
        relayers[cur] = address(0);
        feeOf[cur] = 0;
        relayerCount--;
        emit RemoveRelayer(prev, cur);
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
        if (wad > 0) {
            balanceOf[dst] += wad;
            emit Reward(dst, wad);
        }
    }

    /// Pay rewards to given relayers, optionally rewarding confirmation relayer.
    function _pay_relayers_rewards(DeliveredRelayer[] memory delivery_relayers, address confirm_relayer) private {
        uint256 total_confirm_reward = 0;
        uint256 total_vault_reward = 0;
        for (uint256 i = 0; i < delivery_relayers.length; i++) {
            DeliveredRelayer memory entry = delivery_relayers[i];
            uint256 every_delivery_reward = 0;
            for (uint256 key = entry.begin; key <= entry.end; key++) {
                require(orderOf[key].assignedTime > 0, "!exist");
                // diff_time = settle_time - assign_time
                uint256 diff_time = block.timestamp - orderOf[key].assignedTime;
                // on time
                // [0, slot * n)
                uint32 number = orderOf[key].assignedRelayersNumber;
                if (diff_time < number * relayTime) {
                    // reward and unlock each assign_relayer
                    (uint256 delivery_reward, uint256 confirm_reward, uint256 vault_reward) = _reward_and_unlock_ontime(key, diff_time,  entry.relayer, confirm_relayer);
                    every_delivery_reward += delivery_reward;
                    total_confirm_reward += confirm_reward;
                    total_vault_reward += vault_reward;
                // too late
                // [slot * n, +∞)
                } else {
                    // slash and unlock each assign_relayer
                    uint256 late_time = diff_time - number * relayTime;
                    (uint256 delivery_reward, uint256 confirm_reward) = _slash_and_unlock_late(key, late_time);
                    every_delivery_reward += delivery_reward;
                    total_confirm_reward += confirm_reward;
                }
                delete orderOf[key];
                emit OrderSettled(key, block.timestamp);
            }
            // reward every delivery relayer
            _reward(entry.relayer, every_delivery_reward);
        }
        // reward confirm relayer
        _reward(confirm_relayer, total_confirm_reward);
        // reward vault
        _reward(VAULT, total_vault_reward);
    }

    function _reward_and_unlock_ontime(
        uint256 key,
        uint256 diff_time,
        address delivery_relayer,
        address confirm_relayer
    ) private returns (uint256 delivery_reward, uint256 confirm_reward, uint256 vault_reward) {
        // get the message fee from the last top N relayers
        uint256 message_fee = getOrderFee(key);
        Order memory order = orderOf[key];
        for (uint slot = 0; slot < order.assignedRelayersNumber; slot++) {
            address assign_relayer = assignedRelayers[key][slot];
            // the message delivery in the `slot` assign_relayer
            // [slot, slot+1)
            if (slot * relayTime <= diff_time && diff_time < (slot + 1 ) * relayTime) {
                uint256 base_fee = feeOf[assign_relayer];
                (delivery_reward, confirm_reward, vault_reward) = _distribute_ontime(message_fee, base_fee, assign_relayer, delivery_relayer, confirm_relayer);
            }
            _unlock(assign_relayer, order.collateral);
            delete assignedRelayers[key][slot];
        }
    }

    function _slash_and_unlock_late(uint256 key, uint256 late_time) private returns (uint256 delivery_reward, uint256 confirm_reward) {
        uint256 message_fee = getOrderFee(key);
        // slash fee is linear incremental, and the slop is `late_time / SlashTime`
        Order memory order = orderOf[key];
        uint256 collateral = order.collateral;
        uint256 slash_fee = late_time >= slashTime ? collateral : (collateral * late_time / slashTime);
        for (uint slot = 0; slot < order.assignedRelayersNumber; slot++) {
            address assign_relayer = assignedRelayers[key][slot];
            _slash(assign_relayer, slash_fee);
            _unlock(assign_relayer, (collateral - slash_fee));
            delete assignedRelayers[key][slot];
        }
        // reward_fee = message_fee + slash_fee * AssignedRelayersNumber
        (delivery_reward, confirm_reward) = _distribute_fee(message_fee + slash_fee * order.assignedRelayersNumber);
    }

    function _distribute_ontime(
        uint256 message_fee,
        uint256 base_fee,
        address assign_relayer,
        address delivery_relayer,
        address confirm_relayer
    ) private returns (uint256 delivery_reward, uint256 confirm_reward, uint256 vault_reward) {
        if (base_fee > 0) {
            // 60% * base fee => assigned_relayers_rewards
            uint256 assign_reward = base_fee * 60 / 100;
            // 40% * base fee => other relayer
            uint256 other_reward = base_fee - assign_reward;
            (delivery_reward, confirm_reward) = _distribute_fee(other_reward);
            // if assign_relayer == delivery_relayer, we give the reward to delivery_relayer
            if (assign_relayer == delivery_relayer) {
                delivery_reward += assign_reward;
            // if assign_relayer == confirm_relayer, we give the reward to confirm_relayer
            } else if (assign_relayer == confirm_relayer) {
                confirm_reward += assign_reward;
            // both not, we reward the assign_relayer directlly
            } else {
                _reward(assign_relayer, assign_reward);
            }
        }
        // message fee - base fee => treasury
        vault_reward = message_fee - base_fee;
    }

    function _distribute_fee(uint256 fee) private pure returns (uint256 delivery_reward, uint256 confirm_reward) {
        // 80% * fee => delivery relayer
        delivery_reward = fee * 80 / 100;
        // 20% * fee => confirm relayer
        confirm_reward = fee - delivery_reward;
    }
}
