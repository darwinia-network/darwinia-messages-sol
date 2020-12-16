// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/proxy/Initializable.sol";

import "./Blake2b.sol";
import "./common/Ownable.sol";
import "./common/Pausable.sol";
import "./common/ECDSA.sol";
import "./common/Hash.sol";
import "./common/SafeMath.sol";
import "./common/Input.sol";
import "./MMR.sol";
import "./common/Scale.sol";
import "./SimpleMerkleProof.sol";

pragma experimental ABIEncoderV2;

contract Relay is Ownable, Pausable, Initializable {
    event SetRootEvent(address relayer, bytes32 root, uint256 index);
    event SetAuthritiesEvent(uint32 nonce, address[] authorities, bytes32 benifit);
    event ResetRootEvent(address owner, bytes32 root, uint256 index);
    event ResetLatestIndexEvent(address owner, uint256 index);

    struct Relayers {
        // Each time the relay set is updated, the nonce is incremented
        uint32 nonce;
        // mapping(address => bool) member;
        address[] member;
        uint8 threshold;
    }

    Relayers relayers;

    // 'crab', 'darwinia'
    bytes public networkPrefix;

    // index => mmr root
    // In the Darwinia Network, the mmr root of block 1000 
    // needs to be queried in Log-Other of block 1001.
    mapping(uint32 => bytes32) public mmrRootPool;

    uint32 public latestIndex;

    function initialize(
        uint32 _MMRIndex,
        bytes32 _genesisMMRRoot,
        address[] memory _relayers,
        uint32 _nonce,
        uint8 _threshold,
        bytes memory _prefix
    ) public initializer {
        ownableConstructor();
        pausableConstructor();
        
        _appendRoot(_MMRIndex, _genesisMMRRoot);
        _setRelayer(_nonce, _relayers, bytes32(0));
        _setNetworkPrefix(_prefix);
        relayers.threshold = _threshold;
    }

    function _setRelayer(uint32 nonce, address[] memory accounts, bytes32 benifit) internal {
        require(accounts.length > 0, "Relay: accounts is empty");
        relayers.member = accounts;
        relayers.nonce = nonce;

        emit SetAuthritiesEvent(nonce, accounts, benifit);
    }

    function _appendRoot(uint32 index, bytes32 root) internal {
        require(_getMMRRoot(index) == bytes32(0), "Relay: Index has been set");
        require(latestIndex < index, "Relay: There are already higher blocks");

        _setRoot(index, root);
        _setLatestIndex(index);
    }

    function _setRoot(uint32 index, bytes32 root) internal {
        mmrRootPool[index] = root;
        emit SetRootEvent(_msgSender(), root, index);
    }

    function _setLatestIndex(uint32 index) internal {
        latestIndex = index;
    }

    function _setNetworkPrefix(bytes memory prefix) internal {
        networkPrefix = prefix;
    }

    function _getRelayerCount() internal view returns (uint256) {
        return relayers.member.length;
    }

    function _getNetworkPrefix() internal view returns (bytes memory) {
        return networkPrefix;
    }

    function _getRelayerThreshold() internal view returns (uint8) {
        return relayers.threshold;
    }

    function _getMMRRoot(uint32 index) public view returns (bytes32) {
        return mmrRootPool[index];
    }

    function _isRelayer(address addr) internal view returns (bool) {
        for (uint256 i = 0; i < relayers.member.length; i++) {
            if (addr == relayers.member[i]) {
                return true;
            }
        }
        return false;
    }

    // This method verifies the content of msg by verifying the existing authority collection in the contract. 
    // Ecdsa.recover can recover the signer’s address. 
    // If the signer is matched "isRelayer", it will be counted as a valid signature 
    // and all signatures will be restored. 
    // If the number of qualified signers is greater than Equal to threshold, 
    // the verification is considered successful, otherwise it fails
    function _checkSignature(
        bytes32 hash,
        bytes memory message,
        bytes[] memory signatures
    ) internal view returns (bool) {
        require(
            keccak256(message) == hash,
            "Relay: The message does not match the hash"
        );
        require(signatures.length < 0xffffffff, "Relay: overflow");

        uint16 count;
        for (uint16 i = 0; i < signatures.length; i++) {
            address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signatures[i]);
            if (_isRelayer(signer)) {
                count++;
            }
        }

        uint8 threshold = uint8(
            SafeMath.div(SafeMath.mul(uint256(count), 100), _getRelayerCount())
        );

        return threshold >= _getRelayerThreshold();
    }

    function _checkNetworkPrefix(bytes memory prefix) view public returns (bool) {
      return assertBytesEq(_getNetworkPrefix(), prefix);
    }

    function updateRelayer(
        bytes32 hash,
        bytes memory message,
        bytes[] memory signatures,
        bytes32 benefit
    ) public whenNotPaused {
        // verify hash, signatures (The number of signers must be greater than 2/3 of the total)
        require(
            _checkSignature(hash, message, signatures),
            "Relay: Bad relayer signature"
        );

        // decode message, check nonce and relayer
        Input.Data memory data = Input.from(message);
        (bytes memory prefix, uint32 nonce, address[] memory authorities) = Scale.decodeAuthorities(
            data
        );

        require(_checkNetworkPrefix(prefix), "Relay: Bad network prefix");

        // update nonce,relayer
        _setRelayer(nonce, authorities, benefit);
    }

    function appendRoot(
        bytes32 hash,
        bytes memory message,
        bytes[] memory signatures
    ) public whenNotPaused {
        // verify hash, signatures
        require(
            _checkSignature(hash, message, signatures),
            "Relay: Bad relayer signature"
        );

        // decode message, check nonce and relayer
        Input.Data memory data = Input.from(message);
        (bytes memory prefix, uint32 index, bytes32 root) = Scale.decodeMMRRoot(data);

        require(_checkNetworkPrefix(prefix), "Relay: Bad network prefix");

        // append index, root
        _appendRoot(index, root);
    }

    function resetRoot(uint32 index, bytes32 root) public onlyOwner {
        _setRoot(index, root);
        emit ResetRootEvent(_msgSender(), root, index);
    }

    function verifyRootAndDecodeReceipt(
        bytes32 root,
        uint32 MMRIndex,
        uint32 blockNumber,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory proofstr,
        bytes memory key
    ) public view whenNotPaused returns (bytes memory){
        // verify block proof
        require(
            verifyBlockProof(root, MMRIndex, blockNumber, blockHeader, peaks, siblings),
            "Relay: Block header proof varification failed"
        );

        // get state root
        bytes32 stateRoot = Scale.decodeStateRootFromBlockHeader(blockHeader);

        return getLockTokenReceipt(stateRoot, proofstr, key);
    }

    function verifyBlockProof(
        bytes32 root,
        uint32 MMRIndex,
        uint32 blockNumber,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) public view whenNotPaused returns (bool) {
        require(
            _getMMRRoot(MMRIndex) != bytes32(0),
            "Relay: Not registered under this index"
        );
        require(
            _getMMRRoot(MMRIndex) == root,
            "Relay: Root is different from the root pool"
        );

        return MMR.inclusionProof(root, MMRIndex + 1, blockNumber + 1, blockHeader, peaks, siblings);
    }

    function getLockTokenReceipt(bytes32 root, bytes memory proofstr, bytes memory key)
        public
        view
        whenNotPaused
        returns (bytes memory)
    {
        Input.Data memory data = Input.from(proofstr);

        bytes[] memory proofs = Scale.decodeReceiptProof(data);
        bytes memory result = SimpleMerkleProof.getEvents(root, key, proofs);
        
        return result;
    }

    function resetLatestIndex(uint32 index) public onlyOwner {
        _setLatestIndex(index);
        emit ResetLatestIndexEvent(_msgSender(), index);
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function assertBytesEq(bytes memory a, bytes memory b) internal pure returns (bool){
        bool ok = true;

        if (a.length == b.length) {
            for (uint i = 0; i < a.length; i++) {
                if (a[i] != b[i]) {
                    ok = false;
                }
            }
        } else {
            ok = false;
        }

        return ok;
    }
}