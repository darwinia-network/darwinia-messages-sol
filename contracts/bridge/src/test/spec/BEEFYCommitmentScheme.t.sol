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

pragma solidity 0.8.17;
pragma abicoder v2;

import "../test.sol";
import "../../spec/BEEFYCommitmentScheme.sol";

contract BEEFYCommitmentSchemeTest is DSTest, BEEFYCommitmentScheme {

    // {
    //   "network": "0x50616e676f6c696e000000000000000000000000000000000000000000000000",
    //   "mmr": "0x06b04da502fa50e2d24a8b5d4eae930257d458aab62e913201e4ab57d9044ae8",
    //   "messageRoot": "0x86a09ddd5a659489e07f218b1fba7e260947e4282647c57773d119ba313889bf",
    //   "nextValidatorSet": {
    //     "id": 1,
    //     "len": 4,
    //     "root": "0xa1ce8df8151796ab60157e0c6075a3a4cc170927b1b1fc0f33bde0e274e8f398"
    //   }
    // }
    // 0x50616e676f6c696e00000000000000000000000000000000000000000000000006b04da502fa50e2d24a8b5d4eae930257d458aab62e913201e4ab57d9044ae886a09ddd5a659489e07f218b1fba7e260947e4282647c57773d119ba313889bf010000000000000004000000a1ce8df8151796ab60157e0c6075a3a4cc170927b1b1fc0f33bde0e274e8f398

    function test_encode_next_validator_set() public {
        NextValidatorSet memory set = NextValidatorSet(1, 4, hex"a1ce8df8151796ab60157e0c6075a3a4cc170927b1b1fc0f33bde0e274e8f398");
        assertEq0(encode(set), hex"010000000000000004000000a1ce8df8151796ab60157e0c6075a3a4cc170927b1b1fc0f33bde0e274e8f398");
    }

    function test_hash() public {
        NextValidatorSet memory set = NextValidatorSet(1, 4, hex"a1ce8df8151796ab60157e0c6075a3a4cc170927b1b1fc0f33bde0e274e8f398");
        Payload memory payload = Payload(
            "Pangolin",
            hex"06b04da502fa50e2d24a8b5d4eae930257d458aab62e913201e4ab57d9044ae8",
            hex"86a09ddd5a659489e07f218b1fba7e260947e4282647c57773d119ba313889bf",
            set
        );
        assertEq(hash(payload), hex"011d12969411b75f1252c4e09dd80a69e511911909a9c4e8859852a62ea61a72");
        Commitment memory commmitment = Commitment(
            payload,
            1,
            0
        );
        assertEq(hash(commmitment), hex"f9068ea96e5f6ed9b88ae86c2005398ad71c41f8b0e3d84454179000aa1fccae");
    }

}
