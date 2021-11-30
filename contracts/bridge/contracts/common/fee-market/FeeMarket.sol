pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

contract FeeMarket {
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);
    event Locked(address indexed src, uint wad);
    event UnLocked(address indexed src, uint wad);
    event AddRelayer(address indexed relayer, uint fee);
    event RemoveRelayer(address indexed relayer);

    address internal constant SENTINEL_RELAYERS = address(0x1);

    address public immutable outbound;
    uint public constant immutable COLLATERAL_PERORDER;
    uint public constant immutable ASSIGNED_RELAYERS_NUMBER;

    struct Order {
        uint32 create_time;
        uint32 settle_time;
        address r1;
        address r2;
        address r3;
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public locked;
    mapping(address => address) public relayers;
    mapping(address => uint256) public relayer_fee;
    mapping(uint256 => Order) public orders;
    uint public relayer_count;

    modifier onlyOutBound() {
        require(msg.sender == outbound);
        _;
    }

    modifier enoughBalance() {
        require(balanceOf[msg.sender] >= COLLATERAL_PERORDER);
        _;
    }

    constructor(address _outbound) public {
        outbound = _outbound;
        relayers[SENTINEL_RELAYERS] = SENTINEL_RELAYERS;
    }

    receive() external payable {
    }

    function market_fee() external view returns (uint fee) {
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

    function assigned_relayers(uint nonce) public payable onlyOutBound {
        //selecr assigned_relayers
        _lock(relayer, wad);
        _create_order();
    }

    function enroll_and_lock_collateral(address prev, uint fee) public payable {
        deposit();
        add_relayer(prev, fee);
    }

    function add_relayer(address prev, uint fee) public enoughBalance {
        address cur = msg.sender;
        address next = relayers[prev];
        require(cur != address(0) && cur != SENTINEL_RELAYERS && cur != address(this), "!valid");
        require(relayers[cur] == address(0), "!new");
        require(relayers[prev] != address(0), "!before");
        require(fee >= relayer_fee[prev], "!>=");
        if (next != SENTINEL_RELAYERS) {
            require(fee <= relayer_fee[next], "!<=");
        }
        relayers[cur] = next;
        relayers[prev] = cur;
        relayer_fee[cur] = fee;
        relayer_count++;
        emit AddRelayer(cur, fee);
    }

    function remove_relayer(address prev) public {
        _remove_relayer(prev, msg.sender);
    }

    function _remove_relayer(address prev, address cur) private {
        require(cur != address(0) && cur != SENTINEL_RELAYERS, "!valid");
        require(relayers[prev] == cur, "!cur");
        require(locked[cur] == 0, "!locked");
        relayers[prev] = relayers[cur];
        relayers[cur] = address(0);
        relayer_fee[cur] = 0;
        relayer_count--;
        emit RemoveRelayer(cur);
    }

    function swap_relayer(address old_prev, address new_prev, uint new_fee) public {
        remove_relayer(old_prev);
        add_relayer(new_prev, new_fee);
    }

    function find_last2_relayer() public view returns (address last2, address last1) {
        last2 = SENTINEL_RELAYERS;
        last1 = relayers[SENTINEL_RELAYERS];
        while (relayers[last1] != SENTINEL_RELAYERS) {
            last2 = last1;
            last1 = relayers[last1];
        }
    }

    function getAllRelayers() public view returns (address[] memory) {
        return getRelayers(relayer_count);
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

    function is_relayer(address addr) public view returns (bool) {
        return addr != SENTINEL_GUARDS && relayers[addr] != address(0);
    }

    function _lock(address src, uint wad) internal returns (bool) {
        require(balanceOf[src] >= wad);
        balanceOf[src] -= wad;
        locked[src] += wad;
        emit Locked(src, wad);
        return true;
    }

    function _unlock(address src, uint wad) internal returns (bool) {
        require(locked[src] >= wad);
        locked[src] -= wad;
        balanceOf[src] += wad;
        emit UnLocked(src, wad);
        return true;
    }
}
