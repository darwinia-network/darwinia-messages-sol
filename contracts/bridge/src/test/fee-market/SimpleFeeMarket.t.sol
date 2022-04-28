// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import "../test.sol";
import "../../interfaces/IFeeMarket.sol";
import "../../fee-market/SimpleFeeMarket.sol";

interface Hevm {
    function warp(uint) external;
}

contract SimpleFeeMarketTest is DSTest {
    uint256 constant internal COLLATERAL_PERORDER = 1 ether;
    uint32  constant internal SLASH_TIME = 1 days;
    uint32  constant internal RELAY_TIME = 1 days;

    Hevm internal hevm = Hevm(HEVM_ADDRESS);
    address public self;

    SimpleFeeMarket public market;
    Guy       public a;
    Guy       public b;
    Guy       public c;


   function setUp() public {
       market = new SimpleFeeMarket(
           COLLATERAL_PERORDER,
           SLASH_TIME,
           RELAY_TIME
       );
       self = address(this);
       a = new Guy(market);
       b = new Guy(market);
       c = new Guy(market);
   }

   function test_constructor_args() public {
       assertEq(market.setter(), self);
       assertEq(market.collateralPerOrder(), COLLATERAL_PERORDER);
       assertEq(market.slashTime(), uint(SLASH_TIME));
       assertEq(market.relayTime(), uint(RELAY_TIME));
   }

   function test_set_setter() public {
       market.setSetter(address(0));
       assertEq(market.setter(), address(0));
   }

   function test_set_outbound() public {
       market.setOutbound(self, 1);
       assertEq(market.outbounds(self), 1);
   }

   function test_set_paras() public {
       market.setParameters(2 days, 3 days, 1 wei);
       assertEq(market.slashTime(), uint(2 days));
       assertEq(market.relayTime(), uint(3 days));
       assertEq(market.collateralPerOrder(), 1 wei);
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

       (uint index, address[] memory relayers, uint[] memory fees, uint[] memory balances) = market.getOrderBook(3, true);
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
   }

   function test_assign() public {
       uint key = 1;
       init(key);
       (uint index, address[] memory relayers, uint[] memory fees, uint[] memory balances) = market.getOrderBook(1, false);
       assertEq(index, 1);
       assertEq(relayers[0], address(b));
       assertEq(fees[0], market.feeOf(address(b)));
       assertEq(balances[0], 1 ether);

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

   function newDeliveredRelayers(Guy relayer, uint key) public pure returns (IFeeMarket.DeliveredRelayer[] memory) {
       IFeeMarket.DeliveredRelayer[] memory deliveredRelayers = new IFeeMarket.DeliveredRelayer[](1);
       deliveredRelayers[0] = IFeeMarket.DeliveredRelayer(address(relayer), key, key);
       return deliveredRelayers;
   }

   function assert_eth_balance(Guy guy, uint balance) public {
       assertEq(address(guy).balance, balance);
   }

   function assert_market_balance(Guy guy, uint balance) public {
       assertEq(market.balanceOf(address(guy)), balance);
   }

   function assert_market_balances() public {
       uint ba = market.balanceOf(address(a));
       uint bb = market.balanceOf(address(b));
       uint bc = market.balanceOf(address(c));
       assertEq(ba + bb + bc, market.totalSupply());
   }

   function assert_market_locked(Guy guy, uint locked) public {
       assertEq(market.lockedOf(address(guy)), locked);
   }

   function assert_market_order(Guy guy, uint key) public {
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

   function assert_market_is_relayer(Guy guy) public {
       assertTrue(market.isRelayer(address(guy)));
   }

   function assert_market_is_not_relayer(Guy guy) public {
       assertTrue(!market.isRelayer(address(guy)));
   }

   function assert_market_fee_of(Guy guy, uint fee) public {
       assertEq(market.feeOf(address(guy)), fee);
   }

   function perform_join(Guy guy, uint wad) public {
       guy.join{value: wad}();
   }

   function perform_exit(Guy guy, uint wad) public {
       guy.exit(wad);
   }

   function perform_enroll(Guy guy, address prev, uint wad, uint fee) public {
       guy.enroll{value: wad}(prev, fee);
   }

   function perform_leave(Guy guy, address prev) public {
       guy.leave(prev);
   }

   function perform_enrol(Guy guy, address prev, uint fee) public {
       guy.enrol(prev, fee);
   }

   function perform_delist(Guy guy, address prev) public {
       guy.delist(prev);
   }

   function perform_move(Guy guy, address old_prev, address new_prev, uint new_fee) public {
       guy.move(old_prev, new_prev, new_fee);
   }

   function perform_assign(uint key, uint wad) public {
       market.assign{value: wad}(key);
   }
}

contract Guy {
    SimpleFeeMarket market;

    constructor(SimpleFeeMarket _market) {
        market = _market;
    }

    receive() payable external {}

    function join() payable public {
        market.deposit{value: msg.value}();
    }

    function exit(uint wad) public {
        market.withdraw(wad);
    }

    function enroll(address prev, uint fee) payable public {
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
