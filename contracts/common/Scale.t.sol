pragma solidity ^0.5.16;
import "../ds-test/test.sol";

import "./Input.sol";
import "./Scale.sol";
import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract ScaleTest is DSTest {
    using Input for Input.Data;

    function setUp() public {}

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }

    function testDecodeReceiptProof() public {
        // {
        //     at: 0x1408715bbfa970e0a698a495c5f51ce88a27c23efa20fd66550777e388033836,
        //     proof: [
        //         0x5f00d41e5e16056765bc8461851072c9d735031400000000000000608796090000000002000000010000001702e096b1496b056d5e1ee8e9ef272ff74f05e50884a52318adde16b3b5c6655c3f22aaaaf10536d812c7e097f59e7b769e24341830d42d4551a5c0369a588e4e4000e40b54020000000000000000000000000001000000200600c4192700000000000000000000000000000100000017040f99850f381fdfb5b965617619e59ed082a4515c22967c9c1c94621969362aba0071c6090000000000000000000000000000010000000000401b5f1300000000000000,
        //         0x80ffb9805626b5eeb95364cd35028f6c2e9502e6763c35b49146c3e06eb0fb0c8437e2f5807d6bd45dc0de8a9d3c09ed996173e3228aa1f0c14343e3613600679837c0459e80a1aec849f3a38d7d135fb693c8ea2d30ce711f9de4d6216df3c1a9a1fed7652480f4aa779b91c9584e64e8f414a45415633ddab553b733a8f053ea281665f6e2798037521b6b221966c2e46dadb5ec9f5dd9955bfb6ddc80b7fd2426c8a80b715742807dfc144d3b4073275b82f6e907ec3a2e23734838c9dfd21815d40813f1037bc980257276b52625f532a5b3415084fb91ded52ba117e97209555a8c05054ce5310d80e9e915eca5fb72b66cf72c2e7726f366889ee12e459bb8e4c8db0db83b5b408f80f39c11c55a33b88d079ac377e5fddee82d1c9471f66fb6a28bd3ad96446c983680df791956f0167fb9bed6c0e9fee9de3d6babf3d1152f5deca446dc29a9e9c9fe80d0b26d2c3777a1ff46e46dab9260a54906108d698aa87d6e4a5ebd0d9d9dd416800d5ead5e5c3f67b600edee6ff127a9cdb90fa28f06bc4804ce6dc639c887360b8004815669f5ffdf790a76a75b3b40f700e8bf7d73eb084aaf9dd793eeda3d5252,
        //         0x9eaa394eea5630e07c48ae0c9558cef7298d585f0a98fdbe9ce6c55837576c60c7af3850100500000080798651e0861e900ea90d37dbeea088da90fe28b729ad85b33daa3e3b3dcc9c514c5f0684a022a34dd8bfa2baaf44f172b710040180ebbd938d8e0afb593ff42ca3bc9f58af377da287c9f7c380aa508fa6da70e15580ced43296cd3920efab18447ae4ba50dcc5e87a8db36593ee92756cdd9f36b7598082a75959f024cac266849285f69c1ac49da16ee7801ff4f93fd3cfd3563a47bc605f09cce9c888469bb1a0dceaa129672ef818701043726162,
        //         0x804b0c80feecb9b8cd91aca389352bb80a01c989ade193be7b6361af47238c2974617a1c808294a7635adce51c7ce4f1faa73c37b02852af44ddea9f79eedfea377ce12711801941a755228dfeade556d93ca6af552ca8974fef5d59b56e6ed0083814201fd0800c8012fed6518393bda3231cc9bc889428748a0c4f6e4c832a632469630e203180d80ae17a3fa70e1addb66fd67ff84d2d84c290c73ef9d15d1d748a134d79b15580f732747b5206732f92adaf4f143693558e5cff9d78ae1b2b40040fdcbef859b2
        //     ]
        // }

        // Encode Vec<Vec<proofs>, Vec<keys>>

        bytes memory hexData = hex"1081035f00d41e5e16056765bc8461851072c9d735031400000000000000608796090000000002000000010000001702e096b1496b056d5e1ee8e9ef272ff74f05e50884a52318adde16b3b5c6655c3f22aaaaf10536d812c7e097f59e7b769e24341830d42d4551a5c0369a588e4e4000e40b54020000000000000000000000000001000000200600c4192700000000000000000000000000000100000017040f99850f381fdfb5b965617619e59ed082a4515c22967c9c1c94621969362aba0071c6090000000000000000000000000000010000000000401b5f1300000000000000c10680ffb9805626b5eeb95364cd35028f6c2e9502e6763c35b49146c3e06eb0fb0c8437e2f5807d6bd45dc0de8a9d3c09ed996173e3228aa1f0c14343e3613600679837c0459e80a1aec849f3a38d7d135fb693c8ea2d30ce711f9de4d6216df3c1a9a1fed7652480f4aa779b91c9584e64e8f414a45415633ddab553b733a8f053ea281665f6e2798037521b6b221966c2e46dadb5ec9f5dd9955bfb6ddc80b7fd2426c8a80b715742807dfc144d3b4073275b82f6e907ec3a2e23734838c9dfd21815d40813f1037bc980257276b52625f532a5b3415084fb91ded52ba117e97209555a8c05054ce5310d80e9e915eca5fb72b66cf72c2e7726f366889ee12e459bb8e4c8db0db83b5b408f80f39c11c55a33b88d079ac377e5fddee82d1c9471f66fb6a28bd3ad96446c983680df791956f0167fb9bed6c0e9fee9de3d6babf3d1152f5deca446dc29a9e9c9fe80d0b26d2c3777a1ff46e46dab9260a54906108d698aa87d6e4a5ebd0d9d9dd416800d5ead5e5c3f67b600edee6ff127a9cdb90fa28f06bc4804ce6dc639c887360b8004815669f5ffdf790a76a75b3b40f700e8bf7d73eb084aaf9dd793eeda3d525269039eaa394eea5630e07c48ae0c9558cef7298d585f0a98fdbe9ce6c55837576c60c7af3850100500000080798651e0861e900ea90d37dbeea088da90fe28b729ad85b33daa3e3b3dcc9c514c5f0684a022a34dd8bfa2baaf44f172b710040180ebbd938d8e0afb593ff42ca3bc9f58af377da287c9f7c380aa508fa6da70e15580ced43296cd3920efab18447ae4ba50dcc5e87a8db36593ee92756cdd9f36b7598082a75959f024cac266849285f69c1ac49da16ee7801ff4f93fd3cfd3563a47bc605f09cce9c888469bb1a0dceaa129672ef8187010437261622503804b0c80feecb9b8cd91aca389352bb80a01c989ade193be7b6361af47238c2974617a1c808294a7635adce51c7ce4f1faa73c37b02852af44ddea9f79eedfea377ce12711801941a755228dfeade556d93ca6af552ca8974fef5d59b56e6ed0083814201fd0800c8012fed6518393bda3231cc9bc889428748a0c4f6e4c832a632469630e203180d80ae17a3fa70e1addb66fd67ff84d2d84c290c73ef9d15d1d748a134d79b15580f732747b5206732f92adaf4f143693558e5cff9d78ae1b2b40040fdcbef859b2";
        Input.Data memory data = Input.from(hexData);

        bytes[] memory proofs = Scale.decodeReceiptProof(data);
        bytes[] memory expect = new bytes[](4);
        expect[0] = hex"5f00d41e5e16056765bc8461851072c9d735031400000000000000608796090000000002000000010000001702e096b1496b056d5e1ee8e9ef272ff74f05e50884a52318adde16b3b5c6655c3f22aaaaf10536d812c7e097f59e7b769e24341830d42d4551a5c0369a588e4e4000e40b54020000000000000000000000000001000000200600c4192700000000000000000000000000000100000017040f99850f381fdfb5b965617619e59ed082a4515c22967c9c1c94621969362aba0071c6090000000000000000000000000000010000000000401b5f1300000000000000";
        expect[1] = hex"80ffb9805626b5eeb95364cd35028f6c2e9502e6763c35b49146c3e06eb0fb0c8437e2f5807d6bd45dc0de8a9d3c09ed996173e3228aa1f0c14343e3613600679837c0459e80a1aec849f3a38d7d135fb693c8ea2d30ce711f9de4d6216df3c1a9a1fed7652480f4aa779b91c9584e64e8f414a45415633ddab553b733a8f053ea281665f6e2798037521b6b221966c2e46dadb5ec9f5dd9955bfb6ddc80b7fd2426c8a80b715742807dfc144d3b4073275b82f6e907ec3a2e23734838c9dfd21815d40813f1037bc980257276b52625f532a5b3415084fb91ded52ba117e97209555a8c05054ce5310d80e9e915eca5fb72b66cf72c2e7726f366889ee12e459bb8e4c8db0db83b5b408f80f39c11c55a33b88d079ac377e5fddee82d1c9471f66fb6a28bd3ad96446c983680df791956f0167fb9bed6c0e9fee9de3d6babf3d1152f5deca446dc29a9e9c9fe80d0b26d2c3777a1ff46e46dab9260a54906108d698aa87d6e4a5ebd0d9d9dd416800d5ead5e5c3f67b600edee6ff127a9cdb90fa28f06bc4804ce6dc639c887360b8004815669f5ffdf790a76a75b3b40f700e8bf7d73eb084aaf9dd793eeda3d5252";
        expect[2] = hex"9eaa394eea5630e07c48ae0c9558cef7298d585f0a98fdbe9ce6c55837576c60c7af3850100500000080798651e0861e900ea90d37dbeea088da90fe28b729ad85b33daa3e3b3dcc9c514c5f0684a022a34dd8bfa2baaf44f172b710040180ebbd938d8e0afb593ff42ca3bc9f58af377da287c9f7c380aa508fa6da70e15580ced43296cd3920efab18447ae4ba50dcc5e87a8db36593ee92756cdd9f36b7598082a75959f024cac266849285f69c1ac49da16ee7801ff4f93fd3cfd3563a47bc605f09cce9c888469bb1a0dceaa129672ef818701043726162";
        expect[3] = hex"804b0c80feecb9b8cd91aca389352bb80a01c989ade193be7b6361af47238c2974617a1c808294a7635adce51c7ce4f1faa73c37b02852af44ddea9f79eedfea377ce12711801941a755228dfeade556d93ca6af552ca8974fef5d59b56e6ed0083814201fd0800c8012fed6518393bda3231cc9bc889428748a0c4f6e4c832a632469630e203180d80ae17a3fa70e1addb66fd67ff84d2d84c290c73ef9d15d1d748a134d79b15580f732747b5206732f92adaf4f143693558e5cff9d78ae1b2b40040fdcbef859b2";

        console.log(proofs.length);
        console.logBytes(proofs[0]);

        // console.log(keys.length);
        // console.logBytes(keys[0]);

        assertEq0(proofs[0], expect[0]);
        assertEq0(proofs[1], expect[1]);
        assertEq0(proofs[2], expect[2]);
        assertEq0(proofs[3], expect[3]);
    }

    function testDecodeAccountId() public {
        bytes memory hexData = hex"d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d";
        Input.Data memory data = Input.from(hexData);

        bytes32 accountId = Scale.decodeAccountId(data);
        assertEq32(accountId, bytes32(hex"d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d"));

        console.logBytes32(accountId);
    }

    function testDecodeAccountId2() public {
        bytes memory hexData = hex"d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d0000";
        Input.Data memory data = Input.from(hexData);

        bytes32 accountId = Scale.decodeAccountId(data);
        assertEq32(accountId, bytes32(hex"d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d"));

        console.logBytes32(accountId);
    }

    function testDecodeBalance() public {
        bytes memory hexData = hex"00e87648170000000000000000000000";
        Input.Data memory data = Input.from(hexData);

        uint128 balance = Scale.decodeBalance(data);
        console.log(balance);
        assertEq(uint256(balance), uint256(100000000000));
    }

    function testDecodeLockEvents() public {
        // Vec<Event>    Event = <index, Data>   Data = {accountId, EthereumAddress, types, Balance}
        bytes memory hexData = hex"102403d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27ddac17f958d2ee523a2206206994597c13d831ec700000e5fa31c00000000000000000000002404d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27ddac17f958d2ee523a2206206994597c13d831ec70100e40b5402000000000000000000000024038eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48b20bd5d04be54f870d5c0d3ca85d82b34b8364050000d0b72b6a000000000000000000000024048eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48b20bd5d04be54f870d5c0d3ca85d82b34b8364050100c817a8040000000000000000000000";
        Input.Data memory data = Input.from(hexData);
        Scale.LockEvent[] memory eventData = Scale.decodeLockEvents(data);

        console.log(eventData.length);

        assertEq(eventData.length, 4);

        assertEq32(eventData[0].sender, hex"d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d");
        assertEq(eventData[0].recipient, 0xdAC17F958D2ee523a2206206994597C13D831ec7);
        assertEq(uint(eventData[0].token), 0);
        assertEq(uint(eventData[0].value), 123000000000);

        assertEq32(eventData[1].sender, hex"d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d");
        assertEq(eventData[1].recipient, 0xdAC17F958D2ee523a2206206994597C13D831ec7);
        assertEq(uint(eventData[1].token), 1);
        assertEq(uint(eventData[1].value), 10000000000);

        assertEq32(eventData[2].sender, hex"8eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48");
        assertEq(eventData[2].recipient, 0xB20bd5D04BE54f870D5C0d3cA85d82b34B836405);
        assertEq(uint(eventData[2].token), 0);
        assertEq(uint(eventData[2].value), 456000000000);

        assertEq32(eventData[3].sender, hex"8eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48");
        assertEq(eventData[3].recipient, 0xB20bd5D04BE54f870D5C0d3cA85d82b34B836405);
        assertEq(uint(eventData[3].token), 1);
        assertEq(uint(eventData[3].value), 20000000000);

        console.logBytes32(eventData[0].sender);
        console.logAddress(eventData[0].recipient);
        console.log(uint(eventData[0].token));
        console.log(uint(eventData[0].value));

        console.logBytes32(eventData[1].sender);
        console.logAddress(eventData[1].recipient);
        console.log(uint(eventData[1].token));
        console.log(uint(eventData[1].value));

        console.logBytes32(eventData[2].sender);
        console.logAddress(eventData[2].recipient);
        console.log(uint(eventData[2].token));
        console.log(uint(eventData[2].value));

        console.logBytes32(eventData[3].sender);
        console.logAddress(eventData[3].recipient);
        console.log(uint(eventData[3].token));
        console.log(uint(eventData[3].value));

    }

    function testDecodeEthereumAddress() public {
        bytes memory hexData = hex"b20bd5d04be54f870d5c0d3ca85d82b34b83640501020304";
        Input.Data memory data = Input.from(hexData);

        address addr = Scale.decodeEthereumAddress(data);
        console.logAddress(addr);
        assertEq(addr, 0xB20bd5D04BE54f870D5C0d3cA85d82b34B836405);
    }

    function testDecodeAuthoritiesNonce() public {
        bytes memory hexData = hex"b20bb20bd5d04be54f870d5c0d3ca85d82b34b83640501020304";
        Input.Data memory data = Input.from(hexData);

        uint32 nonce = Scale.decodeAuthoritiesNonce(data);
        console.log(uint256(nonce));
        assertEq(uint256(nonce), 0xb20bb20b);
    }

    function testDecodeAuthorities() public {

        //nonce u32 
        //little 
        bytes memory hexData = hex"00020304b20bd5d04be54f870d5c0d3ca85d82b34b83640585520f613021e5db2afb40cb91ef066ccf212111";
        Input.Data memory data = Input.from(hexData);

        (uint32 nonce, address[] memory authorities) = Scale.decodeAuthorities(data);

        console.log(uint256(nonce));
        console.log(authorities.length);
        console.logAddress(authorities[0]);

        assertEq(uint256(nonce), 131844);
        assertEq(authorities[0], 0xB20bd5D04BE54f870D5C0d3cA85d82b34B836405);
        assertEq(authorities[1], 0x85520f613021E5dB2Afb40cb91EF066CCF212111);

    }

    function testDecodeMMRRoot() public {
        bytes memory hexData = hex"000001020102000000000000000000000000000000000000000000000000000000000009";
        Input.Data memory data = Input.from(hexData);

        (uint32 width, bytes32 root) = Scale.decodeMMRRoot(data);

        console.log(width);
        console.logBytes32(root);

        assertEq(uint256(width), 258);
        assertEq(root, bytes32(hex"0102000000000000000000000000000000000000000000000000000000000009"));
    }
}
