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

pragma solidity 0.8.17;

import "../test.sol";
import "../hevm.sol";
import "../../interfaces/IFeeMarket.sol";
import "../../fee-market/SimpleFeeMarket.sol";

contract SimpleFeeMarketTest is DSTest {
    uint256 constant internal COLLATERAL_PERORDER = 1 ether;
    uint256 constant internal SLASH_TIME = 1 days;
    uint256 constant internal RELAY_TIME = 1 days;
    uint256 constant internal PRICE_RATIO = 800_000;
    uint256 constant internal DUTY_RATIO = 60;

    Hevm internal hevm = Hevm(HEVM_ADDRESS);
    address public self;

    SimpleFeeMarket public market;
    One             public a;
    One             public b;
    One             public c;

    function setUp() public {
         market = new SimpleFeeMarket(
             COLLATERAL_PERORDER,
             SLASH_TIME,
             RELAY_TIME,
             PRICE_RATIO,
             DUTY_RATIO
         );
         self = address(this);
         market.initialize();
         a = new One(market);
         b = new One(market);
         c = new One(market);
    }

    function invariant_setter() public {
         assertEq(market.setter(), self);
    }

    function invariant_totalSupply() public {
        assert_market_balances();
    }

    function test_constructor_args() public {
         assertEq(market.setter(), self);
         assertEq(market.COLLATERAL_PER_ORDER(), COLLATERAL_PERORDER);
         assertEq(market.SLASH_TIME(), uint(SLASH_TIME));
         assertEq(market.RELAY_TIME(), uint(RELAY_TIME));
         assertEq(market.PRICE_RATIO_NUMERATOR(), uint(PRICE_RATIO));
    }

    function test_set_setter_fuzz(address setter) public {
        market.setSetter(setter);
        assertEq(market.setter(), setter);
    }

    function test_set_outbound_fuzz(uint flag) public {
        market.setOutbound(self, flag);
        assertEq(market.outbounds(self), flag);
    }

    function test_initial_state() public {
        assert_eth_balance    (a, 0 ether);
        assert_market_balance (a, 0 ether);
        assert_eth_balance    (b, 0 ether);
        assert_market_balance (b, 0 ether);
        assert_eth_balance    (c, 0 ether);
        assert_market_balance (c, 0 ether);

        assert_market_supply  (0 ether);
    }

    function test_join() public {
        perform_join          (a, 3 ether);
        assert_market_balance (a, 3 ether);
        assert_market_balance (b, 0 ether);
        assert_eth_balance    (a, 0 ether);
        assert_market_supply  (3 ether);

        perform_join          (a, 4 ether);
        assert_market_balance (a, 7 ether);
        assert_market_balance (b, 0 ether);
        assert_eth_balance    (a, 0 ether);
        assert_market_supply  (7 ether);

        perform_join          (b, 5 ether);
        assert_market_balance (b, 5 ether);
        assert_market_balance (a, 7 ether);
        assert_market_supply  (12 ether);
    }

    function testFail_exit_1() public {
        perform_exit          (a, 1 wei);
    }

    function testFail_exit_2() public {
        perform_join          (a, 1 ether);
        perform_exit          (b, 1 wei);
    }

    function testFail_exit_3() public {
        perform_join          (a, 1 ether);
        perform_join          (b, 1 ether);
        perform_exit          (b, 1 ether);
        perform_exit          (b, 1 wei);
    }

    function test_exit() public {
        perform_join          (a, 7 ether);
        assert_market_balance (a, 7 ether);
        assert_eth_balance    (a, 0 ether);

        perform_exit          (a, 3 ether);
        assert_market_balance (a, 4 ether);
        assert_eth_balance    (a, 3 ether);

        perform_exit          (a, 4 ether);
        assert_market_balance (a, 0 ether);
        assert_eth_balance    (a, 7 ether);
    }

    function test_enroll() public {
        perform_enroll           (a, address(1), 1 ether, 1 ether);
        assert_market_is_relayer (a);
        assert_market_fee_of     (a, 1 ether);
        assert_market_balance    (a, 1 ether);
        assert_market_supply     (1 ether);

        perform_enroll           (b, address(a), 1 ether, 1 ether);
        assert_market_is_relayer (b);
        assert_market_fee_of     (b, 1 ether);
        assert_market_balance    (b, 1 ether);
        assert_market_supply     (2 ether);

        perform_enroll           (c, address(b), 1 ether, 1.1 ether);
        assert_market_is_relayer (c);
        assert_market_fee_of     (c, 1.1 ether);
        assert_market_balance    (c, 1 ether);
        assert_market_supply     (3 ether);
    }

    function testFail_enroll_1() public {
        perform_enroll           (a, address(1), 1 ether, 1.1 ether);
        perform_enroll           (b, address(a), 1 ether, 1 ether);
    }

    function testFail_enroll_2() public {
        perform_enroll           (a, address(1), 0.9 ether, 1 ether);
    }

    function test_leave() public {
        perform_enroll           (a, address(1), 7 ether, 1 ether);
        assert_market_is_relayer (a);
        assert_market_fee_of     (a, 1 ether);
        assert_market_balance    (a, 7 ether);
        assert_market_supply     (7 ether);
        assert_eth_balance       (a, 0 ether);

        perform_leave         (a, address(1));
        assert_market_is_not_relayer (a);
        assert_market_fee_of     (a, 0 ether);
        assert_market_balance    (a, 0 ether);
        assert_market_supply     (0 ether);
        assert_eth_balance       (a, 7 ether);
    }

    function test_add_relayer() public {
        perform_join             (a, 3 ether);
        perform_join             (b, 4 ether);
        perform_join             (c, 5 ether);

        perform_enrol            (a, address     ( 1), 1 ether);
        assert_market_is_relayer (a);
        assert_market_fee_of     (a, 1 ether);

        perform_enrol            (b, address     ( a), 1 ether);
        assert_market_is_relayer (b);
        assert_market_fee_of     (b, 1 ether);
        perform_enrol            (c, address     ( b), 1.1 ether);
        assert_market_is_relayer (c);
        assert_market_fee_of     (c, 1.1 ether);
    }

    function test_remove_relayer() public {
        perform_enroll           (a, address(1), 1 ether, 1 ether);
        perform_enroll           (b, address(a), 1 ether, 1 ether);
        perform_enroll           (c, address(b), 1 ether, 1.1 ether);

        perform_delist           (a, address(1));
        assert_market_is_not_relayer (a);
        assert_market_fee_of     (a, 0 ether);
        perform_delist           (b, address(1));
        assert_market_is_not_relayer (b);
        assert_market_fee_of     (b, 0 ether);
        perform_delist           (c, address(1));
        assert_market_is_not_relayer (c);
        assert_market_fee_of     (c, 0 ether);
    }

    function test_move_relayer() public {
        perform_enroll           (a, address(1), 1 ether, 1 ether);
        perform_enroll           (b, address(a), 1 ether, 1 ether);
        perform_enroll           (c, address(b), 1 ether, 1.1 ether);

        perform_move             (a, address(1), address(c), 1.2 ether);
        assert_market_is_relayer (a);
        assert_market_fee_of     (a, 1.2 ether);
    }

    function test_market_status() public {
        perform_enroll           (a, address(1), 1 ether, 1 ether);
        perform_enroll           (b, address(a), 1 ether, 1 ether);
        perform_enroll           (c, address(b), 1 ether, 1.1 ether);

        address top = market.getTopRelayer();
        assertEq(top, address(a));

        (
            uint index,
            address[] memory relayers,
            uint[] memory fees,
            uint[] memory balances,
            uint[] memory locks
        ) = market.getOrderBook(3, true);
        assertEq(index, 3);
        assertEq(relayers[0], address(a));
        assertEq(relayers[1], address(b));
        assertEq(relayers[2], address(c));
        assertEq(fees[0], 1 ether);
        assertEq(fees[1], 1 ether);
        assertEq(fees[2], 1.1 ether);
        assertEq(balances[0], 1 ether);
        assertEq(balances[1], 1 ether);
        assertEq(balances[2], 1 ether);
        assertEq(locks[0], 0 ether);
        assertEq(locks[1], 0 ether);
        assertEq(locks[2], 0 ether);
    }

    function test_assign() public {
        uint key = 1;
        init(key);
        (
            uint index,
            address[] memory relayers,
            uint[] memory fees,
            uint[] memory balances,
            uint[] memory locks
        ) = market.getOrderBook(1, false);
        assertEq(index, 1);
        assertEq(relayers[0], address(b));
        assertEq(fees[0], market.feeOf(address(b)));
        assertEq(balances[0], 1 ether);
        assertEq(locks[0], 0 ether);

        assert_market_locked(a, 1 ether);
        assert_market_locked(b, 0 ether);
        assert_market_locked(c, 0 ether);

        assert_market_order(a, key);
    }

    function test_settle_when_a_relay_and_confirm_at_a_slot() public {
        hevm.warp(1);
        uint key = 1;
        init(key);

        assert_market_balance(a, 0 ether);
        assert_market_balance(b, 1 ether);
        assert_market_balance(c, 1 ether);
        assert_market_locked(a, 1 ether);
        assert_market_locked(b, 0 ether);
        assert_market_locked(c, 0 ether);
        assert_market_supply(4 ether);

        IFeeMarket.DeliveredRelayer[] memory deliveredRelayers = newDeliveredRelayers(a, key);
        assertTrue(market.settle(deliveredRelayers, address(a)));

        assert_market_order_clean(key);

        assert_market_balance(a, 2 ether);
        assert_market_balance(b, 1 ether);
        assert_market_balance(c, 1 ether);
        assert_market_balances();
        assert_market_supply(4 ether);
    }

    function test_settle_when_a_relay_and_b_confirm_at_a_slot() public {
        hevm.warp(1);
        uint key = 1;
        init(key);

        IFeeMarket.DeliveredRelayer[] memory deliveredRelayers = newDeliveredRelayers(a, key);
        assertTrue(market.settle(deliveredRelayers, address(b)));

        assert_market_order_clean(key);

        assert_market_balance(a, 1.92 ether);
        assert_market_balance(b, 1.08 ether);
        assert_market_balance(c, 1 ether);
        assert_market_balances();
        assert_market_supply(4 ether);
    }

    function test_settle_when_b_relay_and_c_confirm_at_a_slot() public {
        hevm.warp(1);
        uint key = 1;
        init(key);

        IFeeMarket.DeliveredRelayer[] memory deliveredRelayers = newDeliveredRelayers(b, key);
        assertTrue(market.settle(deliveredRelayers, address(c)));

        assert_market_order_clean(key);

        assert_market_balance(a, 1.6 ether);
        assert_market_balance(b, 1.32 ether);
        assert_market_balance(c, 1.08 ether);
        assert_market_balances();
        assert_market_supply(4 ether);
    }

    function test_settle_when_a_relay_and_a_confirm_at_a_slot() public {
        hevm.warp(1);
        uint key = 1;
        init(key);

        hevm.warp(1 + RELAY_TIME);
        IFeeMarket.DeliveredRelayer[] memory deliveredRelayers = newDeliveredRelayers(a, key);
        assertTrue(market.settle(deliveredRelayers, address(a)));

        assert_market_order_clean(key);

        assert_market_balance(a, 2 ether);
        assert_market_balance(b, 1 ether);
        assert_market_balance(c, 1 ether);
        assert_market_balances();
        assert_market_supply(4 ether);
    }

    function test_settle_when_b_relay_and_b_confirm_at_a_slot_late() public {
        hevm.warp(1);
        uint key = 1;
        init(key);

        hevm.warp(1 + RELAY_TIME);
        IFeeMarket.DeliveredRelayer[] memory deliveredRelayers = newDeliveredRelayers(b, key);
        assertTrue(market.settle(deliveredRelayers, address(b)));

        assert_market_order_clean(key);

        assert_market_balance(a, 1 ether);
        assert_market_balance(b, 2 ether);
        assert_market_balance(c, 1 ether);
        assert_market_balances();
        assert_market_supply(4 ether);
    }

    function test_settle_when_a_relay_and_b_confirm_late_half_slash() public {
        hevm.warp(1);
        uint key = 1;
        init(key);

        hevm.warp(1 + RELAY_TIME + SLASH_TIME / 2);
        IFeeMarket.DeliveredRelayer[] memory deliveredRelayers = newDeliveredRelayers(a, key);
        assertTrue(market.settle(deliveredRelayers, address(b)));

        assert_market_order_clean(key);

        assert_market_balance(a, 1.7 ether);
        assert_market_balance(b, 1.3 ether);
        assert_market_balance(c, 1 ether);
        assert_market_balances();
        assert_market_supply(4 ether);
    }

    function test_settle_when_a_relay_and_b_confirm_late_all_slash() public {
        hevm.warp(1);
        uint key = 1;
        init(key);

        hevm.warp(1 + RELAY_TIME + SLASH_TIME);
        IFeeMarket.DeliveredRelayer[] memory deliveredRelayers = newDeliveredRelayers(a, key);
        assertTrue(market.settle(deliveredRelayers, address(b)));

        assert_market_order_clean(key);

        assert_market_balance(a, 1.6 ether);
        assert_market_balance(b, 1.4 ether);
        assert_market_balance(c, 1 ether);
        assert_market_balances();
        assert_market_supply(4 ether);
    }

    function test_settle_when_b_relay_and_b_confirm_late_all_slash() public {
        hevm.warp(1);
        uint key = 1;
        init(key);

        hevm.warp(1 + RELAY_TIME + SLASH_TIME);
        IFeeMarket.DeliveredRelayer[] memory deliveredRelayers = newDeliveredRelayers(b, key);
        assertTrue(market.settle(deliveredRelayers, address(b)));

        assert_market_order_clean(key);

        assert_market_balance(a, 0 ether);
        assert_market_balance(b, 3 ether);
        assert_market_balance(c, 1 ether);
        assert_market_balances();
        assert_market_supply(4 ether);
    }

    //------------------------------------------------------------------
    // Helper functions
    //------------------------------------------------------------------

    function init(uint key) public {
        market.setOutbound(self, 1);
        perform_enroll           (a, address(1), 1 ether, 1 ether);
        perform_enroll           (b, address(a), 1 ether, 1 ether);
        perform_enroll           (c, address(b), 1 ether, 1.1 ether);

        perform_assign(key, 1 ether);
    }

    function newDeliveredRelayers(One relayer, uint key) public pure returns (IFeeMarket.DeliveredRelayer[] memory) {
        IFeeMarket.DeliveredRelayer[] memory deliveredRelayers = new IFeeMarket.DeliveredRelayer[](1);
        deliveredRelayers[0] = IFeeMarket.DeliveredRelayer(address(relayer), key, key);
        return deliveredRelayers;
    }

    function assert_eth_balance(One guy, uint balance) public {
        assertEq(address(guy).balance, balance);
    }

    function assert_market_balance(One guy, uint balance) public {
        assertEq(market.balanceOf(address(guy)), balance);
    }

    function assert_market_balances() public {
        uint ba = market.balanceOf(address(a));
        uint bb = market.balanceOf(address(b));
        uint bc = market.balanceOf(address(c));
        assertEq(ba + bb + bc, market.totalSupply());
    }

    function assert_market_locked(One guy, uint locked) public {
        assertEq(market.lockedOf(address(guy)), locked);
    }

    function assert_market_order(One guy, uint key) public {
        (uint32 assignedTime, address assignedRelayer, uint collateral, uint fee) = market.orderOf(key);
        assertEq(assignedTime, block.timestamp);
        assertEq(collateral, COLLATERAL_PERORDER);
        assertEq(assignedRelayer, address(guy));
        assertEq(fee, market.feeOf(assignedRelayer));
    }

    function assert_market_order_clean(uint key) public {
        (uint32 assignedTime, address assignedRelayer, uint collateral, uint fee) = market.orderOf(key);
        assertEq(uint(assignedTime), 0);
        assertEq(assignedRelayer, address(0));
        assertEq(collateral, 0);
        assertEq(fee, 0);

        assert_market_locked(a, 0 ether);
        assert_market_locked(b, 0 ether);
        assert_market_locked(c, 0 ether);
    }

    function assert_market_supply(uint supply) public {
        assertEq(market.totalSupply(), supply);
    }

    function assert_market_is_relayer(One guy) public {
        assertTrue(market.isRelayer(address(guy)));
    }

    function assert_market_is_not_relayer(One guy) public {
        assertTrue(!market.isRelayer(address(guy)));
    }

    function assert_market_fee_of(One guy, uint fee) public {
        assertEq(market.feeOf(address(guy)), fee);
    }

    function perform_join(One guy, uint wad) public {
        guy.join{value: wad}();
    }

    function perform_exit(One guy, uint wad) public {
        guy.exit(wad);
    }

    function perform_enroll(One guy, address prev, uint wad, uint fee) public {
        guy.enroll{value: wad}(prev, fee);
    }

    function perform_leave(One guy, address prev) public {
        guy.leave(prev);
    }

    function perform_enrol(One guy, address prev, uint fee) public {
        guy.enrol(prev, fee);
    }

    function perform_delist(One guy, address prev) public {
        guy.delist(prev);
    }

    function perform_move(One guy, address old_prev, address new_prev, uint new_fee) public {
        guy.move(old_prev, new_prev, new_fee);
    }

    function perform_assign(uint key, uint wad) public {
        market.assign{value: wad}(key);
    }
}

contract One {
    SimpleFeeMarket market;

    constructor(SimpleFeeMarket _market) {
        market = _market;
    }

    receive() external payable {}

    function join() public payable {
        market.deposit{value: msg.value}();
    }

    function exit(uint wad) public {
        market.withdraw(wad);
    }

    function enroll(address prev, uint fee) public payable {
        market.enroll{value: msg.value}(prev, fee);
    }

    function leave(address prev) public {
        market.leave(prev);
    }

    function enrol(address prev, uint fee) public {
        market.enrol(prev, fee);
    }

    function delist(address prev) public {
        market.delist(prev);
    }

    function move(address old_prev, address new_prev, uint new_fee) public {
        market.move(old_prev, new_prev, new_fee);
    }
}
