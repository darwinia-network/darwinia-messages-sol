// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "../../baseapps/pangoro/PangoroAppOnPangolin.sol";
import "../../baseapps/pangolin/PangolinApp.sol";
import "./interface.sol";

contract EchoServer is PangoroAppOnPangolin, PangolinApp {
    function handleEcho(
        bytes memory _msg,
        address receivingContract
    ) public {
        require(
            _isDerivedFromRemote(msg.sender),
            "msg.sender is not derived from remote"
        );

        _remoteTransact(
            _PANGORO_CHAIN_ID,
            _PANGORO_PANGOLIN_LANE_ID,
            28140,
            receivingContract,
            abi.encodeWithSelector(IEcho.receiveEcho.selector, _msg),
            600000 // gas limit
        );
    }

    function setSrcMessageSender(address _srcMessageSender) public {
        srcMessageSender = _srcMessageSender;
    }
}
