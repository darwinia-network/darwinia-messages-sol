// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../../test.sol";
import "../../../truth/darwinia/EcdsaAuthority.sol";

contract EcdsaAuthorityTest is DSTest {
    EcdsaAuthority authority;

    function setUp() public {
        address[] memory relayers = new address[](1);
        relayers[0] = 0x68898dB1012808808C903F390909C52D9F706749;
        authority = new EcdsaAuthority(
            domain_separator(),
            relayers,
            1,
            0
        );
    }

    function domain_separator() public pure returns (bytes32 s) {
        s = keccak256(
                abi.encodePacked(
                    "45",
                    "Pangoro",
                    "::"
                    "ecdsa-authority"
                )
            );
    }

    // keccak256(
    //     "chain_id | spec_name | :: | pallet_name"
    // );
    // string pallet_name = ecdsa-authority
    // string spec_name = Darwinia / Crab / Pangolin
    // string chain_id = 46 / 44 / 43
    function test_domain_separator() public {
        bytes32 s = keccak256(
                abi.encodePacked(
                    "46",
                    "Darwinia",
                    "::"
                    "ecdsa-authority"
                )
            );
        assertEq(s, 0xf8a76f5ceeff36d74ff99c4efc0077bcc334721f17d1d5f17cfca78455967e1e);
        bytes32 h = keccak256(abi.encodePacked("\x19\x01", s, bytes32(0)));
        assertEq(h, 0x1cb3a6858ee5a0568c75b8cee35137943c35e0f81228edb64028fd086efd801b);
    }
}
