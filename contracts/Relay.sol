// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.6.0;

import "./Blake2b.sol";
import "./common/Ownable.sol";
import "./common/Timelock.sol";
import "./common/Pausable.sol";
import "./common/ECDSA.sol";

import "./MMR.sol";
import "./SimpleMerkleProof.sol";

pragma experimental ABIEncoderV2;

contract Relay is Ownable, Pausable, Timelock {
    event InsertRootEvent(address relayer, bytes32 root, uint256 width);
    event SetRootEvent(address relayer, bytes32 root, uint256 width);
    event ResetRootEvent(address owner, bytes32 root, uint256 width);
    event ResetLatestWidthEvent(address owner, uint256 width);

    using Blake2b for Blake2b.Instance;

    struct CandidateRoot {
        uint256 width;
        uint256 time;
        bytes32 data;
        bool dispute;
    }

    mapping(uint256 => bytes32) public mmrRootPool;

    mapping(address => bool) public relayer;
    mapping(address => bool) public supervisor;

    CandidateRoot public candidateRoot;

    // uint256 public latestBlockNumber;
    uint256 public latestWidth;

    constructor(
        uint256 _width,
        bytes32 _genesisMMRRoot,
        address[] memory _relayer
    ) public {
        _appendRoot(_width, _genesisMMRRoot);

        for (uint256 i = 0; i < _relayer.length; ++i) {
            _setRelayer(_relayer[i]);
        }
    }

    modifier isRelayer() {
        require(
            relayer[_msgSender()] || owner() == _msgSender(),
            "Relay: caller is not the relayer or owner"
        );
        _;
    }

    function _setRelayer(address account) internal {
        relayer[account] = true;
    }

    function _removeRelayer(address account) internal {
        relayer[account] = false;
    }

    function _appendRoot(uint256 width, bytes32 root) internal {
        require(
            mmrRootPool[width] == bytes32(0),
            "Relay: Width has been set"
        );
        require(
            latestWidth < width,
            "Relay: There are already higher blocks"
        );

        _setRoot(width, root);
        _setLatestWidth(width);
    }

    function _setRoot(uint256 width, bytes32 root) internal {
        mmrRootPool[width] = root;
        emit SetRootEvent(_msgSender(), root, width);
    }

    function _setLatestWidth(uint256 width) internal {
        latestWidth = width;
    }

    // TODO: 
    function _checkRelayerSignature(bytes32 hash, bytes memory payload, bytes[] memory signatures)
        internal
        returns (bool)
    {
        require(keccak256(payload) == hash, "Relay: The payload does not match the hash");

        for(uint i = 0; i < signatures.length; i++) {
            address signer = ECDSA.recover(hash, signatures[i]);
        }

        
        
        return true;
    }

    function verify(
        bytes32 root,
        uint256 width,
        uint256 index,
        bytes memory value,
        bytes32 valueHash,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) public view {
        require(
            verifyBlockProof(
                root,
                width,
                index,
                value,
                valueHash,
                peaks,
                siblings
            ),
            "Relay: Block header proof varification failed"
        );
    }

    function getMMRRoot(uint256 width) public view returns (bytes32) {
        return mmrRootPool[width];
    }

    function Blake2bHash(bytes memory input) private view returns (bytes32) {
        Blake2b.Instance memory instance = Blake2b.init(hex"", 32);
        return bytesToBytes32(instance.finalize(input), 0);
    }

    function bytesToBytes32(bytes memory b, uint256 offset)
        private
        pure
        returns (bytes32)
    {
        bytes32 out;

        for (uint256 i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function verifyBlockProof(
        bytes32 root,
        uint256 width,
        uint256 index,
        bytes memory value,
        bytes32 valueHash,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) public view whenNotPaused returns (bool) {
        require(
            getMMRRoot(width) == bytes32(0),
            "Relay: Not registered under this width"
        );
        require(
            getMMRRoot(width) == root,
            "Relay: Root is different from the root pool"
        );

        return
            MMR.inclusionProof(
                root,
                width,
                index,
                value,
                valueHash,
                peaks,
                siblings
            );
    }

    function getReceipt(bytes32 root, bytes memory proofs)
        public
        view
        whenNotPaused
        returns (bytes memory)
    {
        Input.Data memory data = Input.from(proofs);

        (bytes[] memory proofs, bytes[] memory keys) = Scale.decodeReceiptProof(
            data
        );
        bytes[] memory result = SimpleMerkleProof.verify(root, proofs, keys);
        return result[0];
    }

    function appendRoot(
        uint256 width,
        bytes32 root,
        bytes32 hash, 
        bytes memory payload,
        bytes[] memory signature
    ) public whenNotPaused {
        require(
            _checkRelayerSignature(hash, payload, signature),
            "Relay: Bad relayer signature"
        );

        _appendRoot(candidateRoot.width, candidateRoot.data);
    }
    
    function resetRoot(uint256 width, bytes32 root) public onlyOwner {
        _setRoot(width, root);
        emit ResetRootEvent(_msgSender(), root, width);
    }

    function resetLatestWidth(uint256 width) public onlyOwner {
        _setLatestWidth(width);
        emit ResetLatestWidthEvent(_msgSender(), width);
    }

    function decodeCompactU8aOffset(bytes1 input0) public pure returns (uint8) {
        bytes1 flag = input0 & bytes1(hex"03");
        if (flag == hex"00") {
            return 1;
        } else if (flag == hex"01") {
            return 2;
        } else if (flag == hex"02") {
            return 4;
        }
        uint8 offset = (uint8(input0) >> 2) + 4 + 1;
        return offset;
    }

    function getStateRootFromBlockHeader(
        uint256 width,
        bytes memory encodedHeader
    ) public pure returns (bytes32) {
        // require(mmrRootPool[width] != bytes32(0x0), "Invalid width");
        // bytes32 inputHash = Blake2bHash(encodedHeader);
        bytes32 state_root;
        uint8 offset = decodeCompactU8aOffset(encodedHeader[32]);
        assembly {
            state_root := mload(add(add(encodedHeader, 0x40), offset))
        }
        return state_root;
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }
}
