// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import "../test.sol";
import "../../spec/SourceChain.sol";

contract SourceChainTest is DSTest, SourceChain {

    function test_constants() public {
        assertEq(
            keccak256(abi.encodePacked(
                "OutboundLaneData(uint256 latest_received_nonce,Message[] messages)",
                "Message(uint256 encoded_key,MessagePayload payload)",
                "MessagePayload(address source,address target,bytes32 encoded_hash)"
                )
            ),
            OUTBOUNDLANEDATA_TYPEHASH
        );

        assertEq(
            keccak256(abi.encodePacked(
                "Message(uint256 encoded_key,MessagePayload payload)",
                "MessagePayload(address source,address target,bytes32 encoded_hash)"
                )
            ),
            MESSAGE_TYPEHASH
        );

        assertEq(
            keccak256(abi.encodePacked(
                "MessagePayload(address source,address target,bytes32 encoded_hash)"
                )
            ),
            MESSAGEPAYLOAD_TYPEHASH
        );
    }

    function test_default_hash() public {
        Message[] memory messages = new Message[](0);
        assertEq(hash(messages), hex"290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563");
        OutboundLaneData memory data = OutboundLaneData(0, messages);
        assertEq(hash(data), hex"d66c5be543d08bf2f429a31cb6dd5d4c8ab76b11d6ecaa6ab6124e1370923ec1");
    }

    function test_hash() public {
        address source = address(0);
        address target = address(1);
        bytes memory encoded = abi.encodeWithSignature("foo()");
        MessagePayload memory payload = MessagePayload(source, target, encoded);
        assertEq(hash(payload), hex"1b9d19ffcdd3c5f3ce909d6f215b8ea1b93481e7d67781edba49e953e387a4c4");

        uint256 encoded_key = uint256(0x0000000000000000000000000000000000000001000000010000000000000001);
        Message memory message = Message(encoded_key, payload);
        Message[] memory messages = new Message[](1);
        messages[0] = message;
        assertEq(hash(messages), hex"5b56e8b948933c311ad8846cf4208391de3dd1e60a09097bf661b2e22cc942a7");

        MessageStorage memory message_storage = MessageStorage(encoded_key, hash(payload));
        MessageStorage[] memory messages_storage = new MessageStorage[](1);
        messages_storage[0] = message_storage;
        assertEq(hash(messages_storage), hash(messages));

        OutboundLaneData memory data = OutboundLaneData(0, messages);
        assertEq(hash(data), hex"28c4b9d94584813960c122787ef4647ba5464f534fbdc7010a7765dcf82b4222");

        OutboundLaneDataStorage memory data_storage = OutboundLaneDataStorage(0, messages_storage);
        assertEq(hash(data_storage), hash(data));
    }

    function test_hash2() public {
        address source = address(0x3DFe30fb7b46b99e234Ed0F725B5304257F78992);
        address target = address(0);
        bytes memory encoded = bytes("");
        MessagePayload memory payload = MessagePayload(source, target, encoded);
        assertEq(hash(payload), hex"3340d482234ce7e8a40473a2903cceccffc8c0c39559be0720e1092494ded74c");

        uint256 encoded_key = uint256(0x0000000000000000000000010000000000000000000000010000000000000001);
        Message memory message = Message(encoded_key, payload);
        Message[] memory messages = new Message[](1);
        messages[0] = message;
        assertEq(hash(messages), hex"8653f2c4b14937dd0c6a582cb6460f49109bee3d515c411135ea9e73bb0ebe92");

        OutboundLaneData memory data = OutboundLaneData(0, messages);
        assertEq(hash(data), hex"502c3362776b751e7f69fdbf349af81a3dbbcc9dcc60bc6f13cfc9d41c77be7e");
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
