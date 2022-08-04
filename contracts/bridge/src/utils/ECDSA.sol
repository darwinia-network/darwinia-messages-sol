// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.7.6;

/// @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
///
/// These functions can be used to verify that a message was signed by the holder
/// of the private keys of a given address.
library ECDSA {
    /// @dev Returns the address that signed a hashed message (`hash`) with
    /// `signature`. This address can then be used for verification purposes.
    ///
    /// The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
    /// this function rejects them by requiring the `s` value to be in the lower
    /// half order, and the `v` value to be either 27 or 28.
    ///
    /// IMPORTANT: `hash` _must_ be the result of a hash operation for the
    /// verification to be secure: it is possible to craft signatures that
    /// recover to arbitrary addresses for non-hashed data. A safe way to ensure
    /// this is by receiving a hash of the original message (which may otherwise
    /// be too long), and then calling {toEthSignedMessageHash} on it.
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        // Check the signature length
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098)
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /// @dev Returns an Ethereum Signed Message, created from a `hash`. This
    /// replicates the behavior of the
    /// https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
    /// JSON-RPC method.
    ///
    /// See {recover}.
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
