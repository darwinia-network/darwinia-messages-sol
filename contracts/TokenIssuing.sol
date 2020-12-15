// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.6.0;

import "./common/Ownable.sol";
import "./common/Pausable.sol";
import "./common/SingletonLock.sol";
import "./interfaces/IRelay.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ISettingsRegistry.sol";
import { ScaleStruct } from "./common/Scale.struct.sol";

import "./common/Scale.sol";
import "./common/SafeMath.sol";

pragma experimental ABIEncoderV2;

contract TokenIssuing is Ownable, Pausable, SingletonLock {

    event MintRingEvent(address recipient, uint256 value, bytes32 accountId);
    event MintKtonEvent(address recipient, uint256 value, bytes32 accountId);
    event MintTokenEvent(address token, address recipient, uint256 value, bytes32 accountId);

    bytes storageKey = hex"f8860dda3d08046cf2706b92bf7202eaae7a79191c90e76297e0895605b8b457";

    ISettingsRegistry public registry;
    IRelay public relay;

    // Record the block height that has been verified
    mapping(uint32 => bool) history;

    function tokenIssuingConstructor(address _registry, address _relay) public singletonLockCall {
        ownableConstructor();

        relay = IRelay(_relay);
        registry = ISettingsRegistry(_registry);
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
      if(relay._getMMRRoot(MMRIndex) == bytes32(0)) {
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
        require(!history[blockNumber], "TokenIssuing:: verifyProof:  The block has been verifiee");

        IRelay relayContract = IRelay(relay);

        bytes memory eventsData = relayContract.verifyRootAndDecodeReceipt(root, MMRIndex, blockNumber, blockHeader, peaks, siblings, proofstr, storageKey);
        Input.Data memory data = Input.from(eventsData);
        
        ScaleStruct.LockEvent[] memory events = Scale.decodeLockEvents(data);

        uint256 len = events.length;

        IERC20 ringContract = IERC20(registry.addressOf(bytes32("CONTRACT_RING_ERC20_TOKEN")));
        IERC20 ktonContract = IERC20(registry.addressOf(bytes32("CONTRACT_KTON_ERC20_TOKEN")));

        for( uint i = 0; i < len; i++ ) {
          ScaleStruct.LockEvent memory item = events[i];
          if(item.token == 0) {
            ringContract.mint(item.recipient, decimalsConverter(item.value));
            emit MintRingEvent(item.recipient, item.value, item.sender);
          }

          if (item.token == 1) {
            ktonContract.mint(item.recipient, decimalsConverter(item.value));
            emit MintKtonEvent(item.recipient, item.value, item.sender);
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
