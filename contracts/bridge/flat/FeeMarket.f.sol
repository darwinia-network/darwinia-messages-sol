// hevm: flattened sources of src/fee-market/FeeMarket.sol
// SPDX-License-Identifier: GPL-3.0 AND MIT
pragma solidity =0.8.17;

////// src/interfaces/IFeeMarket.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

/// @title IFeeMarket
/// @notice A interface for user to enroll to be a relayer.
/// @dev After enroll to be a relyer , you have the duty to relay
/// the meesage which is assigned to you, or you will be slashed
interface IFeeMarket {
    //  Relayer which delivery the messages
    struct DeliveredRelayer {
        // relayer account
        address relayer;
        // encoded message key begin
        uint256 begin;
        // encoded message key end
        uint256 end;
    }
    /// @dev return the real time market maker fee
    /// @notice Revert `!top` when there is not enroll relayer in the fee-market
    function market_fee() external view returns (uint256 fee);
    // Assign new message encoded key to top N relayers in fee-market
    function assign(uint256 nonce) external payable returns(bool);
    // Settle delivered messages and reward/slash relayers
    function settle(DeliveredRelayer[] calldata delivery_relayers, address confirm_relayer) external returns(bool);
}

////// src/proxy/transparent/Address.sol

/* pragma solidity 0.8.17; */

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

////// src/proxy/Initializable.sol
//
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

/* pragma solidity 0.8.17; */

/* import "./transparent/Address.sol"; */

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

////// src/fee-market/FeeMarket.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

/* import "../interfaces/IFeeMarket.sol"; */
/* import "../proxy/Initializable.sol"; */

/// @title FeeMarket
/// @notice FeeMarket is a contract for users to use native tokens of source chain as the method of cross-chain payment
/// @dev See https://github.com/darwinia-network/darwinia-messages-substrate/tree/main/modules/fee-market
contract FeeMarket is Initializable, IFeeMarket {
    /// @notice Relayer count
    uint256 public relayerCount;
    /// @notice Governance role to decide which outbounds message to relay
    address public setter;
    /// @notice Outbounds which message will be relayed by relayers
    mapping(address => uint256) public outbounds;
    /// @notice Balance of the relayer including deposit and eared fee
    mapping(address => uint256) public balanceOf;
    /// @notice Locked balance of relayer for relay messages
    mapping(address => uint256) public lockedOf;
    /// @notice All relayers in fee-market, they are linked one by one and sorted by the relayer fee asc
    mapping(address => address) public relayers;
    /// @notice Maker fee of the relayer
    mapping(address => uint256) public feeOf;
    /// @notice Message encoded key => Order
    mapping(uint256 => Order) public orderOf;
    /// @notice message encoded key => assigned slot => assigned relayer
    mapping(uint256 => mapping(uint256 => OrderExt)) public assignedRelayers;

    /// @notice System treasury
    address public immutable VAULT;
    /// @notice SlashAmount = COLLATERAL_PER_ORDER * LateTime / SLASH_TIME
    uint256 public immutable SLASH_TIME;
    /// @notice Time assigned relayer to relay messages
    uint256 public immutable RELAY_TIME;
    /// @notice Fee market assigned relayers numbers
    uint256 public immutable ASSIGNED_RELAYERS_NUMBER;
    /// @notice RATIO_NUMERATOR of two chain's native token price, denominator of ratio is 1_000_000
    uint256 public immutable PRICE_RATIO_NUMERATOR;
    /// @notice The collateral relayer need to lock for each order.
    uint256 public immutable COLLATERAL_PER_ORDER;
    /// @notice Duty reward ratio
    uint256 public immutable DUTY_REWARD_RATIO;

    address private constant SENTINEL_HEAD = address(0x1);
    address private constant SENTINEL_TAIL = address(0x2);

    event Assigned(uint256 indexed key, uint256 timestamp, uint32 assigned_relayers_number, uint256 collateral);
    event AssignedExt(uint256 indexed key, uint256 slot, address assigned_relayer, uint fee);
    event Delist(address indexed prev, address indexed cur);
    event Deposit(address indexed dst, uint wad);
    event Enrol(address indexed prev, address indexed cur, uint fee);
    event Locked(address indexed src, uint wad);
    event Reward(address indexed dst, uint wad);
    event SetOutbound(address indexed out, uint256 flag);
    event Settled(uint256 indexed key, uint timestamp, address delivery, address confirm);
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
        require(_enough_balance(msg.sender), "!balance");
        _;
    }

    function _enough_balance(address src) private view returns (bool)  {
        return balanceOf[src] >= COLLATERAL_PER_ORDER;
    }

    constructor(
        address _vault,
        uint256 _collateral_perorder,
        uint32 _assigned_relayers_number,
        uint32 _slash_time,
        uint32 _relay_time,
        uint32 _price_ratio_numerator,
        uint256 _duty_reward_ratio
    ) {
        require(_assigned_relayers_number > 0, "!0");
        require(_slash_time > 0 && _relay_time > 0, "!0");
        VAULT = _vault;
        COLLATERAL_PER_ORDER = _collateral_perorder;
        SLASH_TIME = _slash_time;
        RELAY_TIME = _relay_time;
        ASSIGNED_RELAYERS_NUMBER = _assigned_relayers_number;
        PRICE_RATIO_NUMERATOR = _price_ratio_numerator;
        DUTY_REWARD_RATIO = _duty_reward_ratio;
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
        for (uint slot = 0; slot < order.number; ) {
            assigned_relayers[slot] = assignedRelayers[key][slot];
            unchecked { ++slot; }
        }
        return (order, assigned_relayers);
    }

    // Fetch the `count` of order book in fee-market
    // If flag set true, will ignore their balance
    // If flag set false, will ensure their balance is sufficient for lock `COLLATERAL_PER_ORDER`
    function getOrderBook(uint count, bool flag)
        external
        view
        returns (
            uint256,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        require(count <= relayerCount, "!count");
        address[] memory array1 = new address[](count);
        uint256[] memory array2 = new uint256[](count);
        uint256[] memory array3 = new uint256[](count);
        uint256[] memory array4 = new uint256[](count);
        uint index = 0;
        address cur = relayers[SENTINEL_HEAD];
        while (cur != SENTINEL_TAIL && index < count) {
            if (flag || _enough_balance(cur)) {
                array1[index] = cur;
                array2[index] = feeOf[cur];
                array3[index] = balanceOf[cur];
                array4[index] = lockedOf[cur];
                unchecked { index++; }
            }
            cur = relayers[cur];
        }
        return (index, array1, array2, array3, array4);
    }

    // Find top lowest maker fee relayers
    function getTopRelayers() public view returns (address[] memory) {
        require(ASSIGNED_RELAYERS_NUMBER <= relayerCount, "!count");
        address[] memory array = new address[](ASSIGNED_RELAYERS_NUMBER);
        uint index = 0;
        address cur = relayers[SENTINEL_HEAD];
        while (cur != SENTINEL_TAIL && index < ASSIGNED_RELAYERS_NUMBER) {
            if (_enough_balance(cur)) {
                array[index] = cur;
                unchecked { index++; }
            }
            cur = relayers[cur];
        }
        require(index == ASSIGNED_RELAYERS_NUMBER, "!assigned");
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
        if (lockedOf[cur] == 0 && balanceOf[cur] < COLLATERAL_PER_ORDER) {
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
        for (uint slot = 0; slot < top_relayers.length; ) {
            address r = top_relayers[slot];
            require(isRelayer(r), "!relayer");
            _lock(r, COLLATERAL_PER_ORDER);
            assignedRelayers[key][slot] = OrderExt(r, feeOf[r]);
            emit AssignedExt(key, slot, r, feeOf[r]);
            unchecked { ++slot; }
        }
        // Record the assigned time
        orderOf[key] = Order(uint32(block.timestamp), uint32(ASSIGNED_RELAYERS_NUMBER), COLLATERAL_PER_ORDER);
        emit Assigned(key, block.timestamp, uint32(ASSIGNED_RELAYERS_NUMBER), COLLATERAL_PER_ORDER);
        return true;
    }

    // Settle delivered messages and reward/slash relayers
    function settle(DeliveredRelayer[] calldata delivery_relayers, address confirm_relayer) external override onlyOutBound returns (bool) {
        _pay_relayers_rewards(delivery_relayers, confirm_relayer);
        return true;
    }

    function _get_and_prune_top_relayers() private returns (address[] memory) {
        require(ASSIGNED_RELAYERS_NUMBER <= relayerCount, "!count");
        address[] memory array = new address[](ASSIGNED_RELAYERS_NUMBER);
        uint index = 0;
        address prev = SENTINEL_HEAD;
        address cur = relayers[SENTINEL_HEAD];
        while (cur != SENTINEL_TAIL && index < ASSIGNED_RELAYERS_NUMBER) {
            if (_enough_balance(cur)) {
                array[index] = cur;
                unchecked { index++; }
                prev = cur;
            } else {
                prune(prev, cur);
            }
            cur = relayers[prev];
        }
        require(index == ASSIGNED_RELAYERS_NUMBER, "!assigned");
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
        for (uint256 i = 0; i < delivery_relayers.length; ) {
            DeliveredRelayer memory entry = delivery_relayers[i];
            uint256 every_delivery_reward = 0;
            for (uint256 key = entry.begin; key <= entry.end; ) {
                (uint256 delivery_reward, uint256 confirm_reward, uint256 vault_reward) = _settle_order(key);
                every_delivery_reward += delivery_reward;
                total_confirm_reward += confirm_reward;
                total_vault_reward += vault_reward;
                // Clean order
                _clean_order(key);
                emit Settled(key, block.timestamp, entry.relayer, confirm_relayer);
                unchecked { ++key; }
            }
            // Reward every delivery relayer
            _reward(entry.relayer, every_delivery_reward);
            unchecked { ++i; }
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
        is_ontime = diff_time < order.number * RELAY_TIME;
    }

    function _get_slot_price(
        uint256 key,
        uint256 message_fee
    ) private view returns (uint256, uint256) {
        (bool is_ontime, uint diff_time, uint number,) = _get_order_status(key);
        if (is_ontime) {
            for (uint slot = 0; slot < number; ) {
                // The message confirmed in the `slot` assign_relayer
                // [slot, slot+1)
                if (slot * RELAY_TIME <= diff_time && diff_time < (slot + 1) * RELAY_TIME) {
                    uint256 slot_price = getSlotFee(key, slot);
                    return (slot, slot_price);
                }
                unchecked { ++slot; }
            }
            assert(false);
            // resolve warning
            return (0, 0);
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
            for (uint _slot = 0; _slot < number; ) {
                address assign_relayer = getAssignedRelayer(key, _slot);
                if (_slot < slot) {
                    uint256 slash_fee = collateral * 2 / 10;
                    _slash(assign_relayer, slash_fee);
                    _unlock(assign_relayer, (collateral - slash_fee));
                    slot_offensive_slash += slash_fee;
                } else {
                    _unlock(assign_relayer, collateral);
                }
                unchecked { ++_slot; }
            }
        } else {
            uint256 slash_fee = collateral * 2 / 10;
            uint256 remaining = collateral - slash_fee;
            uint256 late_time = diff_time - number * RELAY_TIME;
            slash_fee += late_time >= SLASH_TIME ? remaining : (remaining * late_time / SLASH_TIME);
            for (uint _slot = 0; _slot < number; ) {
                address assign_relayer = getAssignedRelayer(key, _slot);
                _slash(assign_relayer, slash_fee);
                _unlock(assign_relayer, (collateral - slash_fee));
                slot_offensive_slash += slash_fee;
                unchecked { ++_slot; }
            }
        }
    }

    function _do_slot_duty_reward(
        uint256 key,
        uint256 slot,
        uint256 message_surplus
    ) private returns (uint256 slot_duty_reward) {
        (bool is_ontime, , uint number,) = _get_order_status(key);
        uint _total_reward = message_surplus * DUTY_REWARD_RATIO / 100;
        if (is_ontime && _total_reward > 0) {
            require(number > slot, "!slot");
            uint _per_reward = _total_reward / (number - slot);
            for (uint _slot = 0; _slot < number; ) {
                if (_slot >= slot) {
                    address assign_relayer = getAssignedRelayer(key, _slot);
                    _reward(assign_relayer, _per_reward);
                    slot_duty_reward += _per_reward;
                }
                unchecked { ++_slot; }
            }
        } else {
            return 0;
        }
    }

    function _clean_order(uint256 key) private {
        (, , uint number,) = _get_order_status(key);
        for (uint _slot = 0; _slot < number; ) {
            delete assignedRelayers[key][_slot];
            unchecked { ++_slot; }
        }
        delete orderOf[key];
    }

    function _distribute_fee(uint256 fee) private view returns (
        uint256 delivery_reward,
        uint256 confirm_reward
    ) {
        // fee * PRICE_RATIO_NUMERATOR / 1_000_000 => delivery relayer
        delivery_reward = fee * PRICE_RATIO_NUMERATOR / 1_000_000;
        // remaining fee => confirm relayer
        confirm_reward = fee - delivery_reward;
    }
}

