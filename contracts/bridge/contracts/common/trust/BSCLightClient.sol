// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../spec/SourceChain.sol";
import "../spec/TargetChain.sol";
// import "hardhat/console.sol";

interface IBSCBridge {
    function verify_storage_proof(
        address account,
        bytes[] calldata accountProof,
        bytes32[] calldata storageKeys,
        bytes[][] calldata storageProof
    ) external pure returns (bytes32[] memory values);
}

contract BSCLightClient is SourceChain, TargetChain, Ownable {
    event Registry(uint256 bridgedChainPosition, uint256 lanePosition, address lane);

    struct ReceiveProof {
        uint64 latest_received_nonce;
        uint256[] messageKey;
        bytes[] accountProof;
        bytes[][] storageProof;
    }

    struct DeliveryProof {
        uint64 last_confirmed_nonce;
        uint64 last_delivered_nonce;
        uint64[] relayerKey;
        bytes[] accountProof;
        bytes[][] storageProof;
    }

    address internal constant BSC_BRIDGE_PRECOMPILE = address(0x26);

    uint256 public immutable THIS_CHAIN_POSITION;
    uint256 public immutable OUTLANE_MESSAGES_POSITION;
    uint256 public immutable INLANE_RELAYERS_POSITION;

    // bridgedChainPosition => lanePosition => lanes
    mapping(uint32 => mapping(uint32 => address)) lanes;

    constructor(uint32 this_chain_position,  uint32 outlane_messages_position, uint32 inlane_relayers_position) public {
        THIS_CHAIN_POSITION = this_chain_position;
        OUTLANE_MESSAGES_POSITION = outlane_messages_position;
        INLANE_RELAYERS_POSITION = inlane_relayers_position;
    }

    function setBound(uint32 bridgedChainPosition, uint32 outboundPosition, address outbound, uint32 inboundPositon, address inbound) external onlyOwner {
        require(bridgedChainPosition != THIS_CHAIN_POSITION, "BSCLightClient: invalid");
        lanes[bridgedChainPosition][outboundPosition] = outbound;
        lanes[bridgedChainPosition][inboundPositon] = inbound;
        emit Registry(bridgedChainPosition, outboundPosition, outbound);
        emit Registry(bridgedChainPosition, inboundPositon, inbound);
    }

    function verify_messages_proof(
        bytes32 outlane_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view returns (bool) {
        address lane = lanes[chain_pos][lane_pos];
        require(lane != address(0), "BSCLightClient: missing outlane addr");
        ReceiveProof memory proof = abi.decode(encoded_proof, (ReceiveProof));
        // what if size = 0
        uint256 size = proof.messageKey.length;
        require(size > 0 && size == proof.storageProof.length, "BSCLightClient: invalid length");
        uint256 len = 3 * size;
        // find all messages storage keys
        bytes32[] memory storage_keys = new bytes32[](len);
        for (uint64 i=0; i < len; i++) {
            MessageKey memory key = decodeMessageKey(proof.messageKey[i]);
            uint256 messagesLocation = mapLocation(OUTLANE_MESSAGES_POSITION, key.nonce);
            storage_keys[i] = bytes32(messagesLocation);
            storage_keys[i+1] = bytes32(messagesLocation + 1);
            storage_keys[i+2] = bytes32(messagesLocation + 2);
        }

        // extract storage value from proof
        bytes32[] memory values = IBSCBridge(BSC_BRIDGE_PRECOMPILE).verify_storage_proof(
            lane,
            proof.accountProof,
            storage_keys,
            proof.storageProof
        );

        require(len == values.length, "BSCLightClient: invalid values length");
        Message[] memory messages = new Message[](size);
        for (uint64 i=0; i < size; i++) {
           MessagePayload memory payload = MessagePayload(
               address(uint160(uint256(values[3*i]))),
               address(uint160(uint256(values[3*i+1]))),
               values[3*i+2]
           );
           messages[i] = Message(proof.messageKey[i], payload);
        }
        // restruct the out lane data
        OutboundLaneData memory lane_data = OutboundLaneData(proof.latest_received_nonce, messages);
        // check the lane_data_hash
        return outlane_hash == hash(lane_data);
    }

    function mapLocation(uint256 slot, uint256 key) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(key, slot)));
    }

    function verify_messages_delivery_proof(
        bytes32 inlane_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view returns (bool) {
        address lane = lanes[chain_pos][lane_pos];
        require(lane != address(0), "BSCLightClient: missing inlane addr");
        DeliveryProof memory proof = abi.decode(encoded_proof, (DeliveryProof));
        // what if len = 0
        uint256 size = proof.relayerKey.length;
        require(size > 0 && size == proof.storageProof.length, "BSCLightClient: invalid length");
        uint256 len = 3 * size;
        // find all relayers storage keys
        bytes32[] memory storage_keys = new bytes32[](len);
        for (uint64 i=0; i < len; i++) {
            uint64 key = proof.relayerKey[i];
            uint256 relayersLocation = mapLocation(INLANE_RELAYERS_POSITION, key);
            storage_keys[i] = bytes32(relayersLocation);
            storage_keys[i+1] = bytes32(relayersLocation + 1);
            storage_keys[i+2] = bytes32(relayersLocation + 2);
        }

        // extract storage value from proof
        bytes32[] memory values = IBSCBridge(BSC_BRIDGE_PRECOMPILE).verify_storage_proof(
            lane,
            proof.accountProof,
            storage_keys,
            proof.storageProof
        );

        require(len == values.length, "BSCLightClient: invalid values length");
        UnrewardedRelayer[] memory unrewarded_relayers = new UnrewardedRelayer[](size);
        for (uint64 i=0; i < size; i++) {
           bytes32 slot2 = values[3*i+1];
           uint64 begin = uint64(uint256(slot2));
           uint64 end = uint64(uint256(slot2 >> 64));
           unrewarded_relayers[i] = UnrewardedRelayer(
               address(uint160(uint256(values[3*i]))),
               DeliveredMessages(begin, end, uint256(values[3*i+2]))
           );
        }
        // restruct the in lane data
        InboundLaneData memory lane_data = InboundLaneData(unrewarded_relayers, proof.last_confirmed_nonce, proof.last_delivered_nonce);

        // check the lane_data_hash
        return inlane_hash == hash(lane_data);
    }
}
