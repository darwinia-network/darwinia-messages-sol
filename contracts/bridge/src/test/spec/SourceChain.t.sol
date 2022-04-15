// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../../lib/ds-test/src/test.sol";
import "../../spec/SourceChain.sol";

contract SourceChainTest is DSTest, SourceChain {

    function test_constants() public {
        assertEq(
            keccak256(abi.encodePacked(
                "OutboundLaneData(uint256 latest_received_nonce,bytes32 messages)"
                )
            ),
            OUTBOUNDLANEDATA_TYPEHASH
        );

        assertEq(
            keccak256(abi.encodePacked(
                "Message(uint256 encoded_key,MessagePayload data)",
                "MessagePayload(address sourceAccount,address targetContract,bytes32 encodedHash)"
                )
            ),
            MESSAGE_TYPEHASH
        );

        assertEq(
            keccak256(abi.encodePacked(
                "MessagePayload(address sourceAccount,address targetContract,bytes32 encodedHash)"
                )
            ),
            MESSAGEPAYLOAD_TYPEHASH
        );
    }

    function test_default_hash() public {
        Message[] memory messages = new Message[](0);
        assertEq(hash(messages), hex"290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563");
        OutboundLaneData memory data = OutboundLaneData(0, messages);
        assertEq(hash(data), hex"abf32e0b787b02d3d682d36d36f9d3ee2888aa8ca1e44c3846ce95b08916c018");
    }

    function test_hash() public {
        address source = address(0);
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        bytes32 encodedHash = keccak256(encoded);
        MessagePayload memory payload = MessagePayload(source, target, encodedHash);
        assertEq(hash(payload), hex"51137fbb3428b95f656c0fe72c7b4edfedf5dd4891e7bc4b703975f2357c165a");
        uint256 encoded_key = uint256(0x0000000000000000000000000000000000000001000000010000000000000001);
        Message memory message = Message(encoded_key, payload);
        Message[] memory messages = new Message[](1);
        messages[0] = message;
        assertEq(hash(messages), hex"e612808be2be3f985efa8ffc44e0ade409f10045c6a9b563bcbbd0114f101433");
        OutboundLaneData memory data = OutboundLaneData(0, messages);
        assertEq(hash(data), hex"792896df1f2766af7b6612013e8e024fd47e0563adf6b55328d2481806624102");
    }

    function test_decode_message_key() public {
        uint256 encoded_key = uint256(0x0000000000000000000000000000000000000001000000010000000000000001);
        MessageKey memory key = decodeMessageKey(encoded_key);
        assertEq(key.this_chain_id, uint(0));
        assertEq(key.this_lane_id, uint(0));
        assertEq(key.bridged_chain_id, uint(1));
        assertEq(key.bridged_lane_id, uint(1));
        assertEq(key.nonce, uint(1));
    }
}
