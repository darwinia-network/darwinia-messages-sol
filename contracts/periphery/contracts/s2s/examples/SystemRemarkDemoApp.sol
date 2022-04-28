// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "../SmartChainApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";

// contract SystemRemarkDemoApp is PangolinToPangoroApp {
contract SystemRemarkDemoApp is SmartChainApp {

	function systemRemark() public payable {
		// 1. prepare the message
        //    this can be extract to a method:
        //        Types.Message message = Pangoro.buildSystemRemarkCallMessage(hex"12345678");
		System.RemarkCall memory call = System.RemarkCall(
            hex"0001",
            hex"12345678"
        );
        bytes memory callEncoded = System.encodeRemarkCall(call);
        bytes memory message = buildMessage(28080, 2654000000, callEncoded);

        // 2. send the message
        //    Pangolin.sendMessageToPangoro(message);
        //    or
        //    Pangolin.ToPangoro.sendMessage(message);
        sendMessage(bytes2(0x2b03), 0, 200000000000000000000, message);
	}

}