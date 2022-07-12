// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../baseapps/pangoro/PangoroApp.sol";
import "../../baseapps/pangolin/PangolinAppOnPangoro.sol";
import "../../calls/PangolinCalls.sol";
import "./interface.sol";

// ---> Pangoro(client) -> Pangolin(server)
//         ^------------------
//
// 1. Deploy client to Pangoro, deploy server to Pangolin
// 2. Deposit 200 PRINGs to the server contract address
// 3. Call `setSrcMessageSender` to set the other party as its message sender
// 4. Call `client.echo`
contract EchoClient is PangoroApp, PangolinAppOnPangoro {
    function echo(address receivingContract, bytes memory _msg) public payable {
        _remoteTransact(
            _PANGOLIN_CHAIN_ID,
            _PANGORO_PANGOLIN_LANE_ID,
            28140,
            receivingContract,
            abi.encodeWithSelector(
                IEcho.handleEcho.selector,
                _msg,
                address(this)
            ),
            600000 // gas limit
        );
    }

    event EchoReceived(bytes, address);

    function receiveEcho(bytes memory _msg) public {
        require(
            _isDerivedFromRemote(msg.sender),
            "msg.sender is not derived from remote"
        );
        emit EchoReceived(_msg, msg.sender);
    }

    function setSrcMessageSender(address _srcMessageSender) public {
        srcMessageSender = _srcMessageSender;
    }
}
