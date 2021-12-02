pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../../interfaces/IFeeMarket.sol";

contract FeeMarket is IFeeMarket {
    event SetOwner(address indexed o, address indexed n);
    event SetOutbound(address indexed out, uint256 flag);
    event Slash(address indexed src, uint wad);
    event Reward(address indexed dst, uint wad);
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);
    event Locked(address indexed src, uint wad);
    event UnLocked(address indexed src, uint wad);
    event AddRelayer(address indexed relayer, uint fee);
    event RemoveRelayer(address indexed relayer);
    event OrderAssgigned(uint256 indexed key, uint timestamp, address[] top_relayers);
    event OrderSettled(uint256 indexed key, uint timestamp);

    address private constant SENTINEL_RELAYERS = address(0x1);

    address public immutable VAULT;
    uint256 public immutable COLLATERAL_PERORDER;
    uint256 public immutable ASSIGNED_RELAYERS_NUMBER;
    uint256 public immutable SLASH_TIME;
    uint256 public immutable RELAY_TIME;

    address public owner;
    mapping(address => uint256) public outbounds;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public lockedOf;
    mapping(address => address) public relayers;
    uint256 public relayer_count;
    mapping(address => uint256) public feeOf;
    mapping(uint256 => uint256) public orderOf;
    mapping(uint256 => mapping(uint256 => address)) public assigned_relayers;

    modifier onlyOwner {
        require(msg.sender == owner, "!owner");
        _;
    }

    modifier onlyOutBound() {
        require(outbounds[msg.sender] == 1, "!outbound");
        _;
    }

    modifier enoughBalance() {
        require(balanceOf[msg.sender] >= COLLATERAL_PERORDER, "!balance");
        _;
    }

    constructor(
        address _vault,
        uint256 _collateral_perorder,
        uint256 _assigned_relayers_number,
        uint256 _slash_time,
        uint256 _relay_time
    ) public {
        owner = msg.sender;
        VAULT = _vault;
        COLLATERAL_PERORDER = _collateral_perorder;
        ASSIGNED_RELAYERS_NUMBER = _assigned_relayers_number;
        SLASH_TIME = _slash_time;
        RELAY_TIME = _relay_time;
        relayers[SENTINEL_RELAYERS] = SENTINEL_RELAYERS;
    }

    receive() external payable {
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit SetOwner(owner, _owner);
    }

    function setOutbound(address out, uint256 flag) external onlyOwner {
        outbounds[out] = flag;
        emit SetOutbound(out, flag);
    }

    function market_fee() external view override returns (uint fee) {
        address[] memory top_relayers = getTopRelayers();
        address last = top_relayers[top_relayers.length - 1];
        return feeOf[last];
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function assign(uint256 key) public override payable onlyOutBound returns (bool) {
        //select assigned_relayers
        address[] memory top_relayers = getTopRelayers();
        address last = top_relayers[top_relayers.length - 1];
        require(msg.value == feeOf[last], "!fee");
        for (uint slot = 0; slot < top_relayers.length; slot++) {
            address r = top_relayers[slot];
            require(isRelayer(r), "!relayer");
            _lock(r, COLLATERAL_PERORDER);
            assigned_relayers[key][slot] = r;
        }
        orderOf[key] = block.timestamp;
        emit OrderAssgigned(key, block.timestamp, top_relayers);
        return true;
    }

    function settle(DeliveredRelayer[] calldata delivery_relayers, address confirm_relayer) external override onlyOutBound returns (bool) {
        _pay_relayers_rewards(delivery_relayers, confirm_relayer);
        return true;
    }

    function enroll(address prev, uint fee) public payable {
        deposit();
        add_relayer(prev, fee);
    }

    function add_relayer(address prev, uint fee) public enoughBalance {
        address cur = msg.sender;
        address next = relayers[prev];
        require(cur != address(0) && cur != SENTINEL_RELAYERS && cur != address(this), "!valid");
        require(relayers[cur] == address(0), "!new");
        require(relayers[prev] != address(0), "!before");
        require(fee >= feeOf[prev], "!>=");
        if (next != SENTINEL_RELAYERS) {
            require(fee <= feeOf[next], "!<=");
        }
        relayers[cur] = next;
        relayers[prev] = cur;
        feeOf[cur] = fee;
        relayer_count++;
        emit AddRelayer(cur, fee);
    }

    function remove_relayer(address prev) public {
        _remove_relayer(prev, msg.sender);
    }

    function swap_relayer(address old_prev, address new_prev, uint new_fee) public {
        remove_relayer(old_prev);
        add_relayer(new_prev, new_fee);
    }

    function _remove_relayer(address prev, address cur) private {
        require(cur != address(0) && cur != SENTINEL_RELAYERS, "!valid");
        require(relayers[prev] == cur, "!cur");
        require(lockedOf[cur] == 0, "!locked");
        relayers[prev] = relayers[cur];
        relayers[cur] = address(0);
        feeOf[cur] = 0;
        relayer_count--;
        emit RemoveRelayer(cur);
    }

    function getAllRelayers() public view returns (address[] memory) {
        return getRelayers(relayer_count);
    }

    function getTopRelayers() public view returns (address[] memory) {
        require(ASSIGNED_RELAYERS_NUMBER <= relayer_count, "!count");
        address[] memory array = new address[](ASSIGNED_RELAYERS_NUMBER);
        uint index = 0;
        address cur = relayers[SENTINEL_RELAYERS];
        while (cur != SENTINEL_RELAYERS) {
            if (balanceOf[cur] >= COLLATERAL_PERORDER) {
                array[index] = cur;
                index++;
            }
            cur = relayers[cur];
        }
        require(index == ASSIGNED_RELAYERS_NUMBER, "!assigned");
    }

    function getRelayers(uint count) public view returns (address[] memory) {
        require(count <= relayer_count, "!count");
        address[] memory array = new address[](count);
        uint index = 0;
        address cur = relayers[SENTINEL_RELAYERS];
        while (cur != SENTINEL_RELAYERS) {
            array[index] = cur;
            cur = relayers[cur];
            index++;
        }
    }

    function getOrderFee(uint256 key) public view returns (uint256 fee) {
        address last = assigned_relayers[key][ASSIGNED_RELAYERS_NUMBER - 1];
        fee = feeOf[last];
    }

    function isRelayer(address addr) public view returns (bool) {
        return addr != SENTINEL_RELAYERS && relayers[addr] != address(0);
    }

    function _lock(address to, uint wad) internal returns (bool) {
        require(balanceOf[to] >= wad, "!lock");
        balanceOf[to] -= wad;
        lockedOf[to] += wad;
        emit Locked(to, wad);
        return true;
    }

    function _slash_and_unlock(address to, uint slash_wad, uint unlock_wad) internal {
        _slash(to, slash_wad);
        _unlock(to, unlock_wad);
    }

    function _unlock(address to, uint wad) internal returns (bool) {
        require(lockedOf[to] >= wad, "!unlock");
        lockedOf[to] -= wad;
        balanceOf[to] += wad;
        emit UnLocked(to, wad);
        return true;
    }

    function _slash(address src, uint wad) internal {
        require(lockedOf[src] >= wad, "!slash");
        lockedOf[src] -= wad;
        emit Slash(src, wad);
    }

    function _reward(address dst, uint wad) internal {
        if (wad > 0) {
            balanceOf[dst] += wad;
            emit Reward(dst, wad);
        }
    }

    /// Pay rewards to given relayers, optionally rewarding confirmation relayer.
    function _pay_relayers_rewards(DeliveredRelayer[] memory delivery_relayers, address confirm_relayer) internal {
        uint256 total_confirm_reward = 0;
        uint256 total_vault_reward = 0;
        for (uint256 i = 0; i < delivery_relayers.length; i++) {
            DeliveredRelayer memory entry = delivery_relayers[i];
            uint256 every_delivery_reward = 0;
            for (uint256 key = entry.begin; key <= entry.end; key++) {
                require(orderOf[key] > 0, "!exist");
                uint256 diff_time = block.timestamp - orderOf[key];
                // on time
                if (diff_time < ASSIGNED_RELAYERS_NUMBER * RELAY_TIME) {
                    // reward and unlock each assign_relayer
                    (uint256 delivery_reward, uint256 confirm_reward, uint256 vault_reward) = _reward_and_unlock_ontime(key, diff_time,  entry.relayer, confirm_relayer);
                    every_delivery_reward += delivery_reward;
                    total_confirm_reward += confirm_reward;
                    total_vault_reward += vault_reward;
                // too late
                } else {
                    // slash and unlock each assign_relayer
                    (uint256 delivery_reward, uint256 confirm_reward) = _slash_and_unlock_late(key, diff_time);
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
    ) internal returns (uint256 delivery_reward, uint256 confirm_reward, uint256 vault_reward) {
        uint256 real_fee = getOrderFee(key);
        for (uint256 slot = 0; slot < ASSIGNED_RELAYERS_NUMBER; slot++) {
            address assign_relayer = assigned_relayers[key][slot];
            if (diff_time < (slot + 1 ) * RELAY_TIME) {
                uint256 base_fee = feeOf[assign_relayer];
                (delivery_reward, confirm_reward, vault_reward) = _distribute_ontime(real_fee, base_fee, assign_relayer, delivery_relayer, confirm_relayer);
            }
            _unlock(assign_relayer, COLLATERAL_PERORDER);
        }
    }

    function _slash_and_unlock_late(uint256 key, uint256 diff_time) internal returns (uint256 delivery_reward, uint256 confirm_reward) {
        uint256 real_fee = getOrderFee(key);
        uint256 slash_fee = diff_time >= SLASH_TIME ? COLLATERAL_PERORDER : (COLLATERAL_PERORDER * diff_time / SLASH_TIME);
        for (uint256 slot = 0; slot < ASSIGNED_RELAYERS_NUMBER; slot++) {
            address assign_relayer = assigned_relayers[key][slot];
            _slash_and_unlock(assign_relayer, slash_fee, (COLLATERAL_PERORDER - slash_fee));
        }
        (delivery_reward, confirm_reward) = _distribute_fee(real_fee + slash_fee * ASSIGNED_RELAYERS_NUMBER);
    }

    function _distribute_ontime(
        uint256 real_fee,
        uint256 base_fee,
        address assign_relayer,
        address delivery_relayer,
        address confirm_relayer
    ) internal returns (uint256 delivery_reward, uint256 confirm_reward, uint256 vault_reward) {
        if (base_fee > 0) {
            uint256 assign_reward = base_fee * 60 / 100;
            uint256 other_reward = base_fee - assign_reward;
            (delivery_reward, confirm_reward) = _distribute_fee(other_reward);
            if (assign_relayer == delivery_relayer) {
                delivery_reward += assign_reward;
            } else if (assign_relayer == confirm_relayer) {
                confirm_reward += assign_reward;
            } else {
                _reward(assign_relayer, assign_reward);
            }
        }
        vault_reward = real_fee - base_fee;
    }

    function _distribute_fee(uint256 fee) internal pure returns (uint256 delivery_reward, uint256 confirm_reward) {
        delivery_reward = fee * 80 / 100;
        confirm_reward = fee - delivery_reward;
    }
}
