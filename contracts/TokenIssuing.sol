// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/proxy/Initializable.sol";

import "./common/Ownable.sol";
import "./common/Pausable.sol";
import "./interfaces/IRelay.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ISettingsRegistry.sol";
import { ScaleStruct } from "./common/Scale.struct.sol";

import "./common/Scale.sol";
import "./common/SafeMath.sol";

pragma experimental ABIEncoderV2;

contract TokenIssuing is Ownable, Pausable, Initializable {

    event MintRingEvent(address recipient, uint256 value, bytes32 accountId);
    event MintKtonEvent(address recipient, uint256 value, bytes32 accountId);
    event MintTokenEvent(address token, address recipient, uint256 value, bytes32 accountId);

    bytes public storageKey;

    ISettingsRegistry public registry;
    IRelay public relay;

    // Record the block height that has been verified
    mapping(uint32 => bool) history;

    function initialize(address _registry, address _relay, bytes memory _key) public initializer {
        ownableConstructor();
        pausableConstructor();

        relay = IRelay(_relay);
        registry = ISettingsRegistry(_registry);

        storageKey = _key;
    }

    function appendRootAndVerifyProof(
        bytes32 hash,
        bytes memory message,
        bytes[] memory signatures,
        bytes32 root,
        uint32 MMRIndex,
        uint32 blockNumber,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory proofstr
    )
      public
      whenNotPaused
    {
      // If the root of this index already exists in the mmr root pool, 
      // skip append root to save gas
      if(relay.getMMRRoot(MMRIndex) == bytes32(0)) {
        relay.appendRoot(hash, message, signatures);
      }

      verifyProof(root, MMRIndex, blockNumber, blockHeader, peaks, siblings, proofstr);
    }

    function verifyProof(
        bytes32 root,
        uint32 MMRIndex,
        uint32 blockNumber,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory proofstr
    ) 
      public
      whenNotPaused
    {
        require(!history[blockNumber], "TokenIssuing:: verifyProof:  The block has been verified");

        IRelay relayContract = IRelay(relay);

        bytes memory eventsData = relayContract.verifyRootAndDecodeReceipt(root, MMRIndex, blockNumber, blockHeader, peaks, siblings, proofstr, storageKey);
        Input.Data memory data = Input.from(eventsData);
        
        ScaleStruct.LockEvent[] memory events = Scale.decodeLockEvents(data);

        IERC20 ringContract = IERC20(registry.addressOf(bytes32("CONTRACT_RING_ERC20_TOKEN")));
        IERC20 ktonContract = IERC20(registry.addressOf(bytes32("CONTRACT_KTON_ERC20_TOKEN")));

        uint256 len = events.length;

        for( uint i = 0; i < len; i++ ) {
          ScaleStruct.LockEvent memory item = events[i];
          uint256 value = decimalsConverter(item.value);
          if(item.token == 0) {
            ringContract.mint(item.recipient, value);
            emit MintRingEvent(item.recipient, value, item.sender);
          }

          if (item.token == 1) {
            ktonContract.mint(item.recipient, value);
            emit MintKtonEvent(item.recipient, value, item.sender);
          }
        }

        history[blockNumber] = true;
    }

    // The token decimals in Crab, Darwinia Netowrk is 9, in Ethereum Network is 18.
    function decimalsConverter(uint256 darwiniaValue) public pure returns (uint256) {
      return SafeMath.mul(darwiniaValue, 1000000000);
    }

    function setStorageKey(bytes memory key) public onlyOwner {
      storageKey = key;
    } 

    function unpause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }
}
