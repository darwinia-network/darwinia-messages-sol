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
    event SetAuthoritiesEvent(uint32 nonce, address[] authorities, bytes32 beneficiary);
    event ResetRootEvent(address owner, bytes32 root, uint256 index);

    struct Relayers {
        // Each time the relay set is updated, the nonce is incremented
        uint32 nonce;
        // mapping(address => bool) member;
        address[] member;
        uint8 threshold;
    }

    Relayers relayers;

    // 'Crab', 'Darwinia', 'Pangolin'
    bytes private networkPrefix;

    // index => mmr root
    // In the Darwinia Network, the mmr root of block 1000 
    // needs to be queried in Log-Other of block 1001.
    mapping(uint32 => bytes32) public mmrRootPool;

    // _MMRIndex - mmr index or block number corresponding to mmr root
    // _genesisMMRRoot - mmr root
    // _relayers - Keep the same as the "ethereumRelayAuthorities" module in darwinia network
    // _nonce - To prevent replay attacks
    // _threshold - The threshold for a given level can be set to any number from 0-100. This threshold is the amount of signature weight required to authorize an operation at that level.
    // _prefix - The known values are: "Pangolin", "Crab", "Darwinia"
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
        _setRelayThreshold(_threshold);
    }

    /// ==== Getters ==== 
    function getRelayerCount() public view returns (uint256) {
        return relayers.member.length;
    }

    function getRelayerNonce() public view returns (uint32) {
        return relayers.nonce;
    }

    function getRelayer() public view returns (address[] memory) {
        return relayers.member;
    }

    function getNetworkPrefix() public view returns (bytes memory) {
        return networkPrefix;
    }

    function getRelayerThreshold() public view returns (uint8) {
        return relayers.threshold;
    }

    function getMMRRoot(uint32 index) public view returns (bytes32) {
        return mmrRootPool[index];
    }

    function getLockTokenReceipt(bytes32 root, bytes memory eventsProofStr, bytes memory key)
        public
        view
        whenNotPaused
        returns (bytes memory)
    {
        Input.Data memory data = Input.from(eventsProofStr);

        bytes[] memory proofs = Scale.decodeReceiptProof(data);
        bytes memory result = SimpleMerkleProof.getEvents(root, key, proofs);
        
        return result;
    }

    function isRelayer(address addr) public view returns (bool) {
        for (uint256 i = 0; i < relayers.member.length; i++) {
            if (addr == relayers.member[i]) {
                return true;
            }
        }
        return false;
    }

    function checkNetworkPrefix(bytes memory prefix) view public returns (bool) {
      return assertBytesEq(getNetworkPrefix(), prefix);
    }

    function checkRelayerNonce(uint32 nonce) view public returns (bool) {
      return nonce == getRelayerNonce();
    }

    /// ==== Setters ==== 

    // When the darwinia network authorities set is updated, bridger or other users need to submit the new authorities set to the reporter contract by calling this method.
    // message - prefix + nonce + [...relayers]
    // struct{vec<u8>, u32, vec<EthereumAddress>}
    // signatures - signed by personal_sign
    // beneficiary - Keeping the authorities set up-to-date is advocated between the relay contract contract and the darwinia network, and the darwinia network will give partial rewards to the benifit account. benifit is the public key of a darwinia network account
    function updateRelayer(
        bytes memory message,
        bytes[] memory signatures,
        bytes32 beneficiary
    ) public whenNotPaused {
        // verify hash, signatures (The number of signers must be greater than _threshold)
        require(
            _checkSignature(message, signatures),
            "Relay: Bad relayer signature"
        );

        // decode message, check nonce and relayer
        Input.Data memory data = Input.from(message);
        (bytes memory prefix, uint32 nonce, address[] memory authorities) = Scale.decodeAuthorities(
            data
        );

        require(checkNetworkPrefix(prefix), "Relay: Bad network prefix");
        require(checkRelayerNonce(nonce), "Relay: Bad relayer set nonce");

        // update nonce,relayer
        _setRelayer(nonce + 1, authorities, beneficiary);
    }

    // Add a mmr root to the mmr root pool
    // message - bytes4 prefix + uint32 mmr-index + bytes32 mmr-root
    // struct{vec<u8>, u32, H256}
    // encode by scale codec
    // signatures - The signature for message
    // https://github.com/darwinia-network/darwinia-common/pull/381
    function appendRoot(
        bytes memory message,
        bytes[] memory signatures
    ) public whenNotPaused {
        // verify hash, signatures
        require(
            _checkSignature(message, signatures),
            "Relay: Bad relayer signature"
        );

        // decode message, check nonce and relayer
        Input.Data memory data = Input.from(message);
        (bytes memory prefix, uint32 index, bytes32 root) = Scale.decodeMMRRoot(data);

        require(checkNetworkPrefix(prefix), "Relay: Bad network prefix");

        // append index, root
        _appendRoot(index, root);
    }

    function verifyRootAndDecodeReceipt(
        bytes32 root,
        uint32 MMRIndex,
        uint32 blockNumber,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory eventsProofStr,
        bytes memory key
    ) public view whenNotPaused returns (bytes memory){
        // verify block proof
        require(
            verifyBlockProof(root, MMRIndex, blockNumber, blockHeader, peaks, siblings),
            "Relay: Block header proof varification failed"
        );

        // get state root
        bytes32 stateRoot = Scale.decodeStateRootFromBlockHeader(blockHeader);

        return getLockTokenReceipt(stateRoot, eventsProofStr, key);
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
            getMMRRoot(MMRIndex) != bytes32(0),
            "Relay: Not registered under this index"
        );
        require(
            getMMRRoot(MMRIndex) == root,
            "Relay: Root is different from the root pool"
        );

        return MMR.inclusionProof(root, MMRIndex + 1, blockNumber, blockHeader, peaks, siblings);
    }


    /// ==== onlyOwner ==== 
    function resetRoot(uint32 index, bytes32 root) public onlyOwner {
        _setRoot(index, root);
        emit ResetRootEvent(_msgSender(), root, index);
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function resetNetworkPrefix(bytes memory _prefix) public onlyOwner {
        _setNetworkPrefix(_prefix);
    }

    function resetRelayerThreshold(uint8 _threshold) public onlyOwner {
        _setRelayThreshold(_threshold);
    }

    function resetRelayer(uint32 nonce, address[] memory accounts) public onlyOwner {
        _setRelayer(nonce, accounts, bytes32(0));
    }

    /// ==== Internal ==== 
    function _setRelayer(uint32 nonce, address[] memory accounts, bytes32 beneficiary) internal {
        require(accounts.length > 0, "Relay: accounts is empty");
        relayers.member = accounts;
        relayers.nonce = nonce;

        emit SetAuthoritiesEvent(nonce, accounts, beneficiary);
    }

    function _appendRoot(uint32 index, bytes32 root) internal {
        require(getMMRRoot(index) == bytes32(0), "Relay: Index has been set");

        _setRoot(index, root);
    }

    function _setRoot(uint32 index, bytes32 root) internal {
        mmrRootPool[index] = root;
        emit SetRootEvent(_msgSender(), root, index);
    }

    function _setNetworkPrefix(bytes memory prefix) internal {
        networkPrefix = prefix;
    }

    function _setRelayThreshold(uint8 _threshold) internal {
        relayers.threshold = _threshold;
    }

    // This method verifies the content of msg by verifying the existing authority collection in the contract. 
    // Ecdsa.recover can recover the signer’s address. 
    // If the signer is matched "isRelayer", it will be counted as a valid signature 
    // and all signatures will be restored. 
    // If the number of qualified signers is greater than Equal to threshold, 
    // the verification is considered successful, otherwise it fails
    function _checkSignature(
        bytes memory message,
        bytes[] memory signatures
    ) internal view returns (bool) {
        bytes32 hash = keccak256(message);
        require(signatures.length < 0xffffffff, "Relay: overflow");

        uint16 count;
        for (uint16 i = 0; i < signatures.length; i++) {
            address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signatures[i]);
            if (isRelayer(signer)) {
                count++;
            }
        }

        uint8 threshold = uint8(
            SafeMath.div(SafeMath.mul(uint256(count), 100), getRelayerCount())
        );

        return threshold >= getRelayerThreshold();
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