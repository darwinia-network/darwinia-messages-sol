// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.6.0;

import "./Blake2b.sol";
import "./common/Ownable.sol";
import "./common/Timelock.sol";
import "./common/Pausable.sol";
import "./common/ECDSA.sol";
import "./common/Hash.sol";
import "./common/SafeMath.sol";
import "./common/Input.sol";

import "./MMR.sol";
import "./SimpleMerkleProof.sol";

pragma experimental ABIEncoderV2;

contract Relay is Ownable, Pausable, Timelock {
    event InsertRootEvent(address relayer, bytes32 root, uint256 width);
    event SetRootEvent(address relayer, bytes32 root, uint256 width);
    event ResetRootEvent(address owner, bytes32 root, uint256 width);
    event ResetLatestWidthEvent(address owner, uint256 width);

    struct Relayers {
        // Each time the relay set is updated, the nonce is incremented
        uint32 nonce;
        // mapping(address => bool) member;
        address[] member;
        uint16 count;
        uint8 limit;
    }

    Relayers relayers;

    mapping(uint32 => bytes32) public mmrRootPool;

    mapping(address => bool) public relayer;
    mapping(address => bool) public supervisor;

    // uint256 public latestBlockNumber;
    uint32 public latestWidth;

    constructor(
        uint32 _width,
        bytes32 _genesisMMRRoot,
        address[] memory _relayers,
        uint32 _nonce,
        uint8 _relayerLimit
    ) public {
        _appendRoot(_width, _genesisMMRRoot);
        _setRelayer(_nonce, _relayers);
        relayers.limit = _relayerLimit;
    }

    // modifier isRelayer() {
    //     bool isRelayer;
    //     for(uint i = 0; i < relayers.member; i++) {
    //       if(_msgSender() == relayers.member) {
    //         return true;
    //       }
    //     }
    //     return false;
    //     // require(
    //     //     relayers.member[_msgSender()] || owner() == _msgSender(),
    //     //     "Relay: caller is not the relayer or owner"
    //     // );
    //     _;
    // }

    function _setRelayer(uint32 nonce, address[] memory accounts) internal {
        require(accounts.length > 0, "Relay: accounts is empty");
        relayers.member = accounts;
        relayers.nonce = nonce;
        // if(!_isRelayer(account)) {
        //     relayers.member[account] = true;
        //     require(relayers.count < 65535, "Relay: overflow");
        //     relayers.count++;
        // }
    }

    // function _removeRelayer(address account) internal {
    //     if(_isRelayer(account)) {
    //         delete relayers.member[account];
    //         require(relayers.count > 0, "Relay: overflow");
    //         relayers.count--;
    //     }
    // }

    function _appendRoot(uint32 width, bytes32 root) internal {
        require(mmrRootPool[width] == bytes32(0), "Relay: Width has been set");
        require(latestWidth < width, "Relay: There are already higher blocks");

        _setRoot(width, root);
        _setLatestWidth(width);
    }

    function _setRoot(uint32 width, bytes32 root) internal {
        mmrRootPool[width] = root;
        emit SetRootEvent(_msgSender(), root, width);
    }

    function _setLatestWidth(uint32 width) internal {
        latestWidth = width;
    }

    function _getRelayerCount() internal view returns (uint16) {
        return relayers.count;
    }

    function _getRelayerLimit() internal view returns (uint8) {
        return relayers.limit;
    }


    function _getMMRRoot(uint32 width) internal view returns (bytes32) {
        return mmrRootPool[width];
    }

    function _isRelayer(address addr) internal view returns (bool) {
        for (uint256 i = 0; i < relayers.member.length; i++) {
            if (addr == relayers.member[i]) {
                return true;
            }
        }
        return false;
    }

    function _checkSignature(
        bytes32 hash,
        bytes memory payload,
        bytes[] memory signatures
    ) internal view returns (bool) {
        require(
            keccak256(payload) == hash,
            "Relay: The payload does not match the hash"
        );
        require(signatures.length < 0xffffff, "Relay: overflow");

        uint16 count;
        for (uint16 i = 0; i < signatures.length; i++) {
            address signer = ECDSA.recover(hash, signatures[i]);

            if (_isRelayer(signer)) {
                count++;
            }
        }

        uint8 limit = uint8(
            SafeMath.div(SafeMath.mul(uint256(count), 100), _getRelayerCount())
        );

        return limit > _getRelayerLimit();
    }

    function updateRelayer(
        bytes32 hash,
        bytes memory payload,
        bytes[] memory signatures
    ) public {
        // verify hash, signatures (The number of signers must be greater than 2/3 of the total)
        require(
            _checkSignature(hash, payload, signatures),
            "Relay: Bad relayer signature"
        );

        // decode payload, check nonce and relayer
        Input.Data memory data = Input.from(payload);
        (uint32 nonce, address[] memory authorities) = Scale.decodeAuthorities(
            data
        );

        // update nonce,relayer
        _setRelayer(nonce, authorities);
    }

    function appendRoot(
        bytes32 hash,
        bytes memory payload,
        bytes[] memory signatures
    ) public whenNotPaused {
        // verify hash, signatures
        require(
            _checkSignature(hash, payload, signatures),
            "Relay: Bad relayer signature"
        );

        // decode payload, check nonce and relayer
        Input.Data memory data = Input.from(payload);
        (uint32 width, bytes32 root) = Scale.decodeMMRRoot(data);

        // append width,root
        _appendRoot(width, root);
    }

    function resetRoot(uint32 width, bytes32 root) public onlyOwner {
        _setRoot(width, root);
        emit ResetRootEvent(_msgSender(), root, width);
    }

    function verify(
        bytes32 root,
        uint32 width,
        uint256 index,
        bytes memory value,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) public view {
        // verify block proof
        require(
            verifyBlockProof(root, width, index, value, peaks, siblings),
            "Relay: Block header proof varification failed"
        );

        // get state root
        bytes32 stateRoot = Scale.decodeStateRootFromBlockHeader(value);
        // getReceipt();
    }

    function verifyBlockProof(
        bytes32 root,
        uint32 width,
        uint256 index,
        bytes memory value,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) public view whenNotPaused returns (bool) {
        require(
            _getMMRRoot(width) != bytes32(0),
            "Relay: Not registered under this width"
        );
        require(
            _getMMRRoot(width) == root,
            "Relay: Root is different from the root pool"
        );

        return MMR.inclusionProof(root, width, index, value, peaks, siblings);
    }

    // function getLockTokenReceipt(bytes32 root, bytes memory proofstr)
    //     public
    //     view
    //     whenNotPaused
    //     returns (bytes memory)
    // {
    //     Input.Data memory data = Input.from(proofstr);

    //     bytes[] memory proofs = Scale.decodeReceiptProof(
    //         data
    //     );
    //     bytes[] memory result = SimpleMerkleProof.getEvents(root, proofs, keys);
    //     return result[0];
    // }

    function resetLatestWidth(uint32 width) public onlyOwner {
        _setLatestWidth(width);
        emit ResetLatestWidthEvent(_msgSender(), width);
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }
}
