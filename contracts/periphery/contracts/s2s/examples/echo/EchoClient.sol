// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../baseapps/pangoro/PangoroApp.sol";
import "../../calls/PangolinCalls.sol";
import "./interface.sol";

contract EchoClient is PangoroApp {
    function echo(
        address receivingContract,
        bytes memory _msg
    ) public payable {
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

    event EchoReceived(bytes);

    function receiveEcho(bytes memory _msg) public {
        emit EchoReceived(_msg);
    }
}
