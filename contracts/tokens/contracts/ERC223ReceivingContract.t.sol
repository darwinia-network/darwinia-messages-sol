pragma solidity ^0.4.23;

import "ds-test/test.sol";

import "./RING.sol";
import '../node_modules/evolutionlandcommon/contracts/interfaces/ERC223ReceivingContract.sol';

contract TokenReceivingEchoDemo {

    RING ring;

    constructor(address _token) public
    {
        ring = RING(_token);
    }

    function tokenFallback(address _from, uint256 _value, bytes _data) public
    {
        // check that the msg.sender _token is equal to token address
        require(msg.sender == address(ring));
        
        ring.transfer(_from, _value);
    }

    function anotherTokenFallback(address _from, uint256 _value, bytes _data) public
    {
        // check that the msg.sender _token is equal to token address
        require(msg.sender == address(ring));
        
        ring.transfer(_from, _value);
    }

    function tokenFallback(address _from, uint256 _value) public
    {
        // check that the msg.sender _token is equal to token address
        require(msg.sender == address(ring));
        
        ring.transfer(_from, _value);
    }
}

contract Nothing {
    // do not have receiveToken API
}

contract ERC223ReceivingContractTest is DSTest, TokenController {
    TokenReceivingEchoDemo echo;
    RING ring;
    Nothing nothing;

    function proxyPayment(address _owner) payable returns(bool){
        return true;
    }

    function onTransfer(address _from, address _to, uint _amount) returns(bool){
        return true;
    }

    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool)
    {
        return true;
    }

    function setUp() {
        ring = new RING();
        echo = new TokenReceivingEchoDemo(address(ring));
        nothing = new Nothing();
    }

    function testFail_basic_sanity() {
        ring.mint(this, 10000);

        assertEq(ring.balanceOf(this) , 10000);

        // fail
        ring.transfer(address(nothing), 100, "0x");

        assertEq(ring.balanceOf(this) , 10000);

    }

    function test_token_fall_back_with_data() {
        ring.mint(this, 10000);
        ring.transfer(address(echo), 5000, "");

        assertEq(ring.balanceOf(this) , 10000);

        // https://github.com/dapphub/dapp/issues/65
        // need manual testing
        //ring.transfer(address(echo), 5000, "0x", "anotherTokenFallback(address,uint256,bytes)");

        //assertEq(ring.balanceOf(this) , 10000);

        ring.transfer(address(nothing), 100);
    }

    function test_token_fall_back_direct() {
        ring.mint(this, 10000);

        assertTrue(ring.balanceOf(this) == 10000);

        ring.transfer(address(echo), 5000);

        assertTrue(ring.balanceOf(this) == 10000);
    }
}