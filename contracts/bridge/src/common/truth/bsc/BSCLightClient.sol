// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../../interfaces/ILightClient.sol";
import "../../spec/SourceChain.sol";
import "../../spec/TargetChain.sol";

interface IBSCBridge {
    function verify_single_storage_proof(
        address account,
        bytes[] calldata accountProof,
        bytes32 storageKey,
        bytes[] calldata storageProof
    ) external view returns (bytes memory value);

    function verify_multi_storage_proof(
        address account,
        bytes[] calldata accountProof,
        bytes32[] calldata storageKeys,
        bytes[][] calldata storageProof
    ) external view returns (bytes[] memory values);
}

contract BSCLightClient is SourceChain, TargetChain {
    event Registry(uint256 bridgedChainPosition, uint256 lanePosition, address lane);

    event Debug(uint64 indexed latest_received_nonce, uint256 indexed key, address indexed sourceAccount, address targetContract, bytes32 encodedHash);

    struct ReceiveProof {
        bytes[] accountProof;
        bytes[] laneIDProof;
        bytes[] laneNonceProof;
        bytes[][] laneMessagesProof;
    }

    struct DeliveryProof {
        bytes[] accountProof;
        bytes[] laneNonceProof;
        bytes[][] laneRelayersProof;
    }

    address internal constant BSC_BRIDGE_PRECOMPILE = address(0x1a);

    uint256 public immutable THIS_CHAIN_POSITION;
    uint256 public immutable LANE_IDENTIFY_SLOT;
    uint256 public immutable LANE_NONCE_SLOT;
    uint256 public immutable LANE_MESSAGE_SLOT;

    // bridgedChainPosition => lanePosition => lanes
    mapping(uint32 => mapping(uint32 => address)) lanes;

    address public setter;

    modifier onlySetter {
        require(msg.sender == setter, "BSCLightClient: forbidden");
        _;
    }

    function changeSetter(address _setter) external onlySetter {
        setter = _setter;
    }

    constructor(
        uint32 this_chain_position,
        uint256 lane_identify_slot,
        uint256 lane_nonce_slot,
        uint256 lane_message_slot
    ) {
        THIS_CHAIN_POSITION = this_chain_position;
        LANE_IDENTIFY_SLOT = lane_identify_slot;
        LANE_NONCE_SLOT = lane_nonce_slot;
        LANE_MESSAGE_SLOT = lane_message_slot;
        setter = msg.sender;
    }

    function registry(uint32 bridgedChainPosition, uint32 outboundPosition, address outbound, uint32 inboundPositon, address inbound) external onlySetter {
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
    ) external returns (bool) {
        address lane = lanes[chain_pos][lane_pos];
        require(lane != address(0), "BSCLightClient: missing outlane addr");
        ReceiveProof memory proof = abi.decode(encoded_proof, (ReceiveProof));

        // extract identify storage value from proof
        uint identify_storage = toUint(IBSCBridge(BSC_BRIDGE_PRECOMPILE).verify_single_storage_proof(
            lane,
            proof.accountProof,
            bytes32(LANE_IDENTIFY_SLOT),
            proof.laneIDProof
        ));

        // extract nonce storage value from proof
        uint nonce_storage = toUint(IBSCBridge(BSC_BRIDGE_PRECOMPILE).verify_single_storage_proof(
            lane,
            proof.accountProof,
            bytes32(LANE_NONCE_SLOT),
            proof.laneNonceProof
        ));

        OutboundLaneData memory lane_data = build_outlane(identify_storage, nonce_storage, lane, proof);
        // check the lane_data_hash
        return outlane_hash == hash(lane_data);
    }

    function build_outlane(uint identify_storage, uint nonce_storage, address lane, ReceiveProof memory proof) internal returns (OutboundLaneData memory lane_data) {
        // restruct the outlane data
        uint64 latest_received_nonce = uint64(nonce_storage);
        uint256 size = uint64(nonce_storage >> 64) - latest_received_nonce;
        if (size > 0) {
            // find all messages storage keys
            bytes32[] memory storage_keys = build_message_keys(latest_received_nonce, size);

            // extract messages storage value from proof
            bytes[] memory values = IBSCBridge(BSC_BRIDGE_PRECOMPILE).verify_multi_storage_proof(
                lane,
                proof.accountProof,
                storage_keys,
                proof.laneMessagesProof
            );

            require((3 * size) == values.length, "BSCLightClient: invalid values length");
            Message[] memory messages = new Message[](size);
            for (uint64 i=0; i < size; i++) {
               MessagePayload memory payload = MessagePayload(
                   address(uint160(toUint(values[3*i]))),
                   address(uint160(toUint(values[3*i+1]))),
                   toBytes32(values[3*i+2])
               );
               uint256 key = (identify_storage << 64) + latest_received_nonce + 1 + i;
               messages[i] = Message(key, payload);
               emit Debug(latest_received_nonce, key, payload.sourceAccount, payload.targetContract, payload.encodedHash);
            }
            lane_data.messages = messages;
        }
        lane_data.latest_received_nonce = latest_received_nonce;
    }

    function build_message_keys(uint64 latest_received_nonce, uint size) internal view returns (bytes32[] memory) {
        bytes32[] memory storage_keys = new bytes32[](3 * size);
        uint64 begin = latest_received_nonce + 1;
        for (uint64 index=0; index < size; index++) {
            uint64 nonce = begin + index;
            uint256 messagesLocation = mapLocation(LANE_MESSAGE_SLOT, nonce);
            storage_keys[index] = bytes32(messagesLocation);
            storage_keys[index+1] = bytes32(messagesLocation + 1);
            storage_keys[index+2] = bytes32(messagesLocation + 2);
        }
        return storage_keys;
    }

    function verify_messages_delivery_proof(
        bytes32 inlane_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view returns (bool) {
        address lane = lanes[chain_pos][lane_pos];
        require(lane != address(0), "BSCLightClient: missing outlane addr");
        DeliveryProof memory proof = abi.decode(encoded_proof, (DeliveryProof));

        // extract nonce storage value from proof
        uint nonce_storage = toUint(IBSCBridge(BSC_BRIDGE_PRECOMPILE).verify_single_storage_proof(
            lane,
            proof.accountProof,
            bytes32(LANE_NONCE_SLOT),
            proof.laneNonceProof
        ));

        uint64 last_confirmed_nonce = uint64(nonce_storage);
        uint64 last_delivered_nonce = uint64(nonce_storage >> 64);
        uint64 front = uint64(nonce_storage >> 128);
        uint64 back = uint64(nonce_storage >> 192);
        uint256 size = back >= front ? back - front + 1 : 0;
        // restruct the in lane data
        InboundLaneData memory lane_data;
        if (size > 0) {
            uint256 len = 3 * size;
            // find all messages storage keys
            bytes32[] memory storage_keys = new bytes32[](len);
            for (uint64 index=0; index < size; index++) {
                uint256 relayersLocation = mapLocation(LANE_MESSAGE_SLOT, front + index);
                storage_keys[index] = bytes32(relayersLocation);
                storage_keys[index+1] = bytes32(relayersLocation + 1);
                storage_keys[index+2] = bytes32(relayersLocation + 2);
            }

            // extract messages storage value from proof
            bytes[] memory values = IBSCBridge(BSC_BRIDGE_PRECOMPILE).verify_multi_storage_proof(
                lane,
                proof.accountProof,
                storage_keys,
                proof.laneRelayersProof
            );

            require(len == values.length, "BSCLightClient: invalid values length");
            UnrewardedRelayer[] memory unrewarded_relayers = new UnrewardedRelayer[](size);
            for (uint64 i=0; i < size; i++) {
               uint slot2 = toUint(values[3*i+1]);
               unrewarded_relayers[i] = UnrewardedRelayer(
                   address(uint160(toUint(values[3*i]))),
                   DeliveredMessages(
                       uint64(slot2),
                       uint64(slot2 >> 64),
                       toUint(values[3*i+2])
                   )
               );
            }
            lane_data.relayers = unrewarded_relayers;
        }
        lane_data.last_confirmed_nonce = last_confirmed_nonce;
        lane_data.last_delivered_nonce = last_delivered_nonce;
        // check the lane_data_hash
        return inlane_hash == hash(lane_data);
    }

    function toUint(bytes memory bts) internal pure returns (uint data) {
        uint len = bts.length;
        if (len == 0) {
            return 0;
        }
        assembly {
            data := div(mload(add(bts, 32)), exp(256, sub(32, len)))
        }
    }

    function toBytes32(bytes memory bts) internal pure returns (bytes32 data) {
        return bytes32(toUint(bts));
    }

    function mapLocation(uint256 slot, uint256 key) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(key, slot)));
    }
}
