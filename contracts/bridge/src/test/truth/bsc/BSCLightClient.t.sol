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

import "../../test.sol";
import "../../../truth/bsc/BSCLightClient.sol";
import "../../../spec/BinanceSmartChain.sol";

contract BSCLightClientTest is DSTest, BinanceSmartChain {
    uint64 constant private CHAIN_ID = 56;
    uint64 constant private PERIOD = 3;

    ParliaWrapper public parlia;

    function setUp() public {
        BSCHeader memory genesis_header = build_genesis_header();
        parlia = new ParliaWrapper(CHAIN_ID, PERIOD, genesis_header);
    }

    function test_constructor_args() public {
        BSCHeader memory header = build_genesis_header();
        assert_finalized_checkpoint(header);
    }

    function assert_finalized_checkpoint(BSCHeader memory cp) internal {
        (
            bytes32 parent_hash,
            bytes32 state_root,
            bytes32 transactions_root,
            bytes32 receipts_root,
            uint256 number,
            uint256 timestamp,
            bytes32 hash
        ) = parlia.finalized_checkpoint();
        assertEq(parent_hash, cp.parent_hash);
        assertEq(state_root, cp.state_root);
        assertEq(receipts_root, cp.receipts_root);
        assertEq(transactions_root, cp.transactions_root);
        assertEq(number, cp.number);
        assertEq(timestamp, cp.timestamp);
        assertEq(hash, parlia.hash_block(cp));
        address[] memory expected_signers = parlia.extract_authorities(cp.extra_data);
        assertEq(parlia.length_of_finalized_authorities(), expected_signers.length);
        for (uint i = 0; i < expected_signers.length; i++) {
            assertEq(parlia.finalized_authorities_at(i), expected_signers[i]);
        }
    }

    function test_recover_creator() public {
        BSCHeader memory header = build_genesis_header();
        address creator = parlia.recover_creator(header);
        assertEq(creator, header.coinbase);
    }

    function test_extract_authorities() public {
        BSCHeader memory header = build_genesis_header();
        address[] memory signers = parlia.extract_authorities(header.extra_data);
        address[] memory expected_signers = build_expected_signers();
        assertEq(signers.length, expected_signers.length);
        for (uint i = 0; i < signers.length; i++) {
            assertEq(signers[i], expected_signers[i]);
        }
    }

    function testFail_import_finalized_epoch_header() public {
        BSCHeader memory checkpoint = build_checkpoint();
        BSCHeader[] memory headers = new BSCHeader[](1);
        headers[0] = checkpoint;
        parlia.import_finalized_epoch_header(headers);
    }

    function test_import_finalized_epoch_header() public {
        BSCHeader[] memory headers = build_headers_7706000_to_77060010();
        parlia.import_finalized_epoch_header(headers);
        BSCHeader memory checkpoint = headers[0];
        assert_finalized_checkpoint(checkpoint);
    }

    function build_headers_7706000_to_77060010() internal pure returns (BSCHeader[] memory) {
        BSCHeader[] memory headers = new BSCHeader[](11);
        headers[0] = BSCHeader({
            difficulty: 0x2,
            extra_data: hex'd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b72465176c461afb316ebc773c61faee85a6515daa295e26495cef6f69dfa69911d9d8e4f3bbadb89b29a97c6effb8a411dabc6adeefaa84f5067c8bbe2d4c407bbe49438ed859fe965b140dcf1aab71a93f349bbafec1551819b8be1efea2fc46ca749aa14430b3230294d12c6ab2aac5c2cd68e80b16b581685b1ded8013785d6623cc18d214320b6bb6475970f657164e5b75689b64b7fd1fa275f334f28e1872b61c6014342d914470ec7ac2975be345796c2b7ae2f5b9e386cd1b50a4550696d957cb4900f03a8b6c8fd93d6f4cea42bbb345dbc6f0dfdb5bec739bb832254baf4e8b4cc26bd2b52b31389b56e98b9f8ccdafcc39f3c7d6ebf637c9151673cbc36b88a6f79b60359f141df90a0c745125b131caaffd12b8f7166496996a7da21cf1f1b04d9b3e26a3d077be807dddb074639cd9fa61b47676c064fc50d62cce2fd7544e0b2cc94692d4a704debef7bcb61328e2d3a739effcd3a99387d015e260eefac72ebea1e9ae3261a475a27bb1028f140bc2a7c843318afdea0a6e3c511bbd10f4519ece37dc24887e11b55dee226379db83cffc681495730c11fdde79ba4c0c675b589d9452d45327429ff925359ca25b1cc0245ffb869dbbcffb5a0d3c72f103a1dcb28b105926c636747dbc265f8dda0090784be3febffdd7909aa6f416d200',
            gas_limit: 0x391a17f,
            gas_used: 0x151a7b2,
            log_bloom: hex'4f7a466ebd89d672e9d73378d03b85204720e75e9f9fae20b14a6c5faf1ca5f8dd50d5b1077036e1596ef22860dca322ddd28cc18be6b1638e5bbddd76251bde57fc9d06a7421b5b5d0d88bcb9b920adeed3dbb09fd55b16add5f588deb6bcf64bbd59bfab4b82517a1c8fc342233ba17a394a6dc5afbfd0acfc443a4472212640cf294f9bd864a4ac85465edaea789a007e7f17c231c4ae790e2ced62eaef10835c4864c7e5b64ad9f511def73a0762450659825f60ceb48c9e88b6e77584816a2eb57fdaba54b71d785c8b85de3386e544ccf213ecdc942ef0193afae9ecee93ff04ff9016e06a03393d4d8ae14a250c9dd71bf09fee6de26e54f405d947e1',
            coinbase: 0x72b61c6014342d914470eC7aC2975bE345796c2b,
            mix_digest: 0x0000000000000000000000000000000000000000000000000000000000000000,
            nonce: 0x0000000000000000,
            number: 0x759590,
            parent_hash: 0x898c926e404409d6151d0e0ea156770fdaa2b31f8115b5f20bcb1b6cb4dc34c3,
            receipts_root: 0x04aea8f3d2471b7ae64bce5dde7bb8eafa4cf73c65eab5cc049f92b3fda65dcc,
            uncle_hash: 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347,
            state_root: 0x5d03a66ae7fdcc6bff51e4c0cf40c6ec2d291090bddd9073ca4203d84b099bb9,
            timestamp: 0x60ac738f,
            transactions_root: 0xb3db66bc49eac913dbdbe8aeaaee891762a6c5c28990c3f5f161726a8cb1c41d
    });
        headers[1] = BSCHeader({
            difficulty: 0x2,
			extra_data: hex'd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b785af1d1bd69b06d22eb4185264881ebfa7e03c13336a379d6e295668d9a2019934a6b95af37bdd281c76c9902d4f92a45b0f17e554fed2660921001db734d86e01',
			gas_limit: 0x3938700,
			gas_used: 0xaba7f5,
			log_bloom: hex'ac62c6b962661253cd46815c9c8860fa4e2422209e14a422004fad6682204176241150b66142930017045c2002594102e85215a4925e846817403044336500c40efe34b5a206920a0d84c6090030ea66be9389b11149cd8ec1458010e073a21ac0319a36eb02cc3a5008044048093a3db0374279c6aa5e70cc75403a202a04a0487a40050bdf46a41885444409364b9860365d8dc0e0ce087d80044d21100dd2224c01205448d04c0a04c337036ae5106d581982d5e1f063856b9c2a2460e0a601425d0328134473567828c8dbaa15e869444c7910244094286041fbb2cce50220570529602148048329232c89c040000c1a876ce18e46f012c96415a8b90860',
			coinbase: 0x7AE2F5B9e386cd1B50A4550696D957cB4900f03a,
			mix_digest: 0x0000000000000000000000000000000000000000000000000000000000000000,
			nonce: 0x0000000000000000,
			number: 0x759591,
			parent_hash: 0x2af8376a302e60d766a74c4b4bbc98be08611865f3545da840062eabac511aff,
			receipts_root: 0x91d41e3697f96ed7b05f10c0463ac53b4e24ad815c263374f5772ece54c74492,
			uncle_hash: 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347,
			state_root: 0x4c933c90f8d6e1ffecb5f3dfa920f42800e5a933e89270afe4a2399e89d945e3,
			timestamp: 0x60ac7392,
			transactions_root: 0x3d9f0347d455bbf966c644add2ec3ba72dce962ce0fee509c876abf333a8752d
        });
        headers[2] = BSCHeader({
            difficulty: 0x2,
			extra_data: hex'd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b791a889653e7fae96d9088f4f51e29fabab8946c97b3808c2701fcfa4fec15e310c5ca3dc8ce47b68a6375c43f7f13880b007929274c7c8353aa0849358dd5dfe00',
			gas_limit: 0x3938700,
			gas_used: 0x1292023,
			log_bloom: hex'0ef226282e8c5270b86ba86cd3942c9d6c084350d6c2c5204132cc15a1f9b991a048d04766127304435bb0c66e9acd033840811cb24e21ba067c2e7034a1bacd2cea6c841829024e8177d87b28a725a038f3282019c9abf6a66db800c4fa0e0d637b10358a0330d0749d47470208b8211a116274c78f1f600435143740302acb181c5015881354c05af5551c28b16d53102544c50623d828a58415e162720c7a8301862f974f587aae46c30e13a42c1a0c078b10d3e0dc6888eab232a6c1d1cc315a1d67c29369a34e584042c1d333d0fe56943f012444b01c41c82b3a7dacc680925ead003943280148710c0d28ddc20a1c5d7860eeceea6620202a2c18e162',
			coinbase: 0x8b6C8fd93d6F4CeA42Bbb345DBc6F0DFdb5bEc73,
			mix_digest: 0x0000000000000000000000000000000000000000000000000000000000000000,
			nonce: 0x0000000000000000,
			number: 0x759592,
			parent_hash: 0x686bc4a6f643ff9de728a2386a2db77894faa255dc41b8e1f6e9cff4cb27e685,
			receipts_root: 0x627077d9b0b683d8855106eb7f4e6c97776cac9e4c43b1296f65a3955e224bbf,
			uncle_hash: 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347,
			state_root: 0xe3013ffbcd54608736b6660a9440a0e02cdff3093b81f24c6f319dffa02f8794,
			timestamp: 0x60ac7395,
			transactions_root: 0xb55bcd0739f2419b124f182e42f542fdd5edf2e461a7f622e69e8d0d30b81381
        });
        headers[3] = BSCHeader({
            difficulty: 0x2,
			extra_data: hex'd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b701765b0e4da320698b090670aaaddbee8a88960d68e9116a8a961f8489d091e53fcf58d47d8c52432252c5704eef934c6830145ef08b4f53c02c71a39d9ed4bf00',
			gas_limit: 0x391b12a,
			gas_used: 0x16f1ddc,
			log_bloom: hex'0df90f3ffea6141387740c60fda57ccdefa56f2a8fc5de6b076e9dffb23951f2d53ef427a0e21725670a1efe2baf4b8adff637395e3f132aae760e6bbce7b0f401f33e9e993094ce1d56d36b2cb733e72eb8ce4f9b5c78df99b7bcbde196cf66dfd9d6ffff2e823f17df824bfc2ea9a6ae3562f4d7cbffe184ff167fe6346bcb9f68218549bf5d99fbc5e71594abafdf6bfd57f58b358c2839b6046db7bec89bde6bad5f77dae16a4f4d4f3c172eb7b9df0d23f777c43e7917e3bdfc6ca9f0877c16f6b692c5f92e0aaebcc7cc43b7ea78f5f8d3851ca6387d35e7ff8a3efec539d77c240468ca1c6ba313fcbe956fa458bc177af1cf4fef7b2a34541d8b0cfa',
			coinbase: 0x9bB832254BAf4E8B4cc26bD2B52B31389B56E98B,
			mix_digest: 0x0000000000000000000000000000000000000000000000000000000000000000,
			nonce: 0x0000000000000000,
			number: 0x759593,
			parent_hash: 0x4ace1c429b3bf4f75654b2747610e3df4321a3b115f46cf4c3e4cdc07e16384b,
			receipts_root: 0x5f19964cce2277394b244076c855aa4be02731628ecc5661bb19ced5ba47a759,
			uncle_hash: 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347,
			state_root: 0x87243b67114f19232756fba8e0dd2ac9a0e0b1c3e5c719bfb678545aa69553ef,
			timestamp: 0x60ac7398,
			transactions_root: 0x4c3c1d213b8fd8a940264e5b7f33081405c99f9f8c13a79140efe2a181cff43b
        });
        headers[4] = BSCHeader({
            difficulty: 0x2,
			extra_data: hex'd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b7efe068383e6ff15b5935f2c7e30ad5a53f131d172887a871c491e1444f6966164c4886535fb16165589bcd55e12ca3400a02471c9f5210da0e9e32fe1b20a01a00',
			gas_limit: 0x3904626,
			gas_used: 0x1960a85,
			log_bloom: hex'5c676edd1e7c5a3127f8c17af63126eb68422b42c62e65b41c689f6cc58b0ff587bada5e1e80735d777ddde69b8ea772b8e7e767f2eaa42b257a9c54732771ce11d5eabfe492e273c548e80d806703357eb76ca25f4c6eeb9fc7f53da37d4e3e0bc9f075cf2e58082fb99bcc24b8a863fe7136578eaeb7fe1fbd2033742124eb3cccb114538b341c7cce5f4da3d66aeb606477971042cc5a75c5307f662a39dcea68c02f7a4ee4d94b3ceb0ffa4eff292a2e1c7c59a55e3c2b629ff13e27f8f63adba42a3bc88da3d05a42ea9cc6578daf74ecdf413c61d2e039519b78e0af56bdf2d5ef626e479e63f07fe894a80b1a1c3af9b970ef58f473b2f85d798bdeff',
			coinbase: 0x9F8cCdaFCc39F3c7D6EBf637c9151673CBc36b88,
			mix_digest: 0x0000000000000000000000000000000000000000000000000000000000000000,
			nonce: 0x0000000000000000,
			number: 0x759594,
			parent_hash: 0x9cfdde281bcb5ce7a945b7e7b65937d57144bd7c4f2afc78861b8278f962f1a9,
			receipts_root: 0xd714a1aeadca6d956d61c4d3341256d6751c2c9ab627e73a313fd7fbd1f81f05,
			uncle_hash: 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347,
			state_root: 0x736f5dd240ebd69038b16ab87cb346bf6e0ecbbb5f108793a5e5ba5cf767b5c4,
			timestamp: 0x60ac739b,
			transactions_root: 0xa7b26890bfd73389e92b1d90d1bd8a352b8993213f94d6318219deb956ee6c51
        });
        headers[5] = BSCHeader({
            difficulty: 0x2,
			extra_data: hex'd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b7b8970ca7f3216b6f47a0ddf1164656f3d37beb4ae8c4fbda579033777bc33253045829c87353268b567640c7ceddb87c6f0ed1477ca29ea34cf8e62e3cf8305200',
			gas_limit: 0x38f16f0,
			gas_used: 0x128e65a,
			log_bloom: hex'cc612e08064c2050034c21c5d82571a9f104423ecf01c60002c6c5e2658425100510d0642c12b3dc39409938a0b817218e720bac528844c029010c55333da14010ba8150503082f22188639a5197e2ac2e912b3110d40a42c807b30a9956a84e4b8dd9272f13c94054482442e422a820582513dd842e9fa886bf42316c0230633878be2615bbe62028d0404410024c9a28b47605a03b9238f58c145946211ad2c30001404468b6ca3127171092661570e50e42c615e619b08f1383a4c05bc0844e33202f22f8583bd0310ac783069524f494263200f00210480a603a100fe68c10df054b00a0c03e0f2111d8cd0217065dbc0718e5de466658e12ccca7a34870',
			coinbase: 0xa6f79B60359f141df90A0C745125B131cAAfFD12,
			mix_digest: 0x0000000000000000000000000000000000000000000000000000000000000000,
			nonce: 0x0000000000000000,
			number: 0x759595,
			parent_hash: 0x881be32a4b68f7ecc8408f029126767b27dede57a62f769b2d8f7ef71113c64d,
			receipts_root: 0x02279165675ef03901bada335794d15561a3086088f7051c22cc67e8884a3fd3,
			uncle_hash: 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347,
			state_root: 0x91000dc3ee541fcbfbf9e50adbbd661573662c7a35cc77898ca26a51eb00311a,
			timestamp: 0x60ac739e,
			transactions_root: 0x1f1db2afc29bb24f4f179817bb21fd920097a35396a7b41f7d2a7151ac358f09
        });
        headers[6] = BSCHeader({
            difficulty: 0x2,
			extra_data: hex'd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b747e9be4caa3872a963f1e4131b9bba7b576d3f4429bddb7737219111753ce03054bb3ae9ad5a5981011e222a4b387236ca936b60cce8435c8f5da20b647329fd00',
			gas_limit: 0x392a605,
			gas_used: 0x1542dc9,
			log_bloom: hex'8bf25afb7ed81a50daf8a9ec918183b2fc006600ce86c5f0599acdc79430711043ded543a442163c5d59d7ecffb83c1018c288c9821fd53d6fdecae8ba2f30be98f2dc130d5cd3df210baa29a1a4b5bef893c8bafb4508569895a0ac83df97326e18d17eaa0a10d0125846506ac0f969de3b4637c5af765bce7165f60e0eaca5189682bbc9df4210f59747489898099062f6fcd74abfd9b93d8c15fb434c9cb1eecb081b5dfeb1687f864b9647fd7f2cbe6b4975df80a8b8c95a9e76667148757d8e1d26d53e430f989cc5c8a853f329ed4058bfa0a601335ec7927a2af9e678d3d45ff98228c9e259f7f1ea3f52fc4a1d2c942a7376ce68e628dec80c90b3ea',
			coinbase: 0xB8f7166496996A7da21cF1f1b04d9B3E26a3d077,
			mix_digest: 0x0000000000000000000000000000000000000000000000000000000000000000,
			nonce: 0x0000000000000000,
			number: 0x759596,
			parent_hash: 0x083de17c79eb4e9b671ebea582b386b26e37e191ffb878700acf82d0a8060990,
			receipts_root: 0x6cbd7fbee301afc02cb1dd87bcc070270b2daeb41976361d3d3929a6f4d7e972,
			uncle_hash: 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347,
			state_root: 0x40b4f6168b0b7c36b95762ef6f1146339123431a0543e899525039bf033c811a,
			timestamp: 0x60ac73a1,
			transactions_root: 0x3283014eb5d06d8ab3530d750f42e41b82de6b3f55a7ddbb09dac74ae7c1f3c3
        });
        headers[7] = BSCHeader({
            difficulty: 0x2,
			extra_data: hex'd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b719723d29f7d061fab02990c800ac6d389996d9122adfb4aca5a04991ce662b2503623114073a52deb87a7105274086bf57e844f88924795ed5633da344252fd300',
			gas_limit: 0x3938700,
			gas_used: 0x11d4503,
			log_bloom: hex'5ff58a3dfe0e713e8b4d8c54d84880fb572cba398695c444785fdec7a424ddd48511523757b9af84df105a240409611e8a5217cc9250021af5040471b125244498faae278938f95f01c542aaa0c44c306f926f2970534c27e4a5f32382b784187b3956a49b0ee12970484b712620a810b29540d580ab37e904fb72b244a200621fea6810a9aa1d08bda05c680aba68cfa434f5034026ec0c3483147ccb7a6efacf90972e46eac4485b14612abf0a57b51e6e01e21bc1d8ab21621969300cedd5592fb5ae207c410623021aa30927798af1e4ac33e407ccb4203348321369af379497050e1563466fdba805080e0835052e7c8d6ce9af5473bb9a22a6e28f14ec',
			coinbase: 0xBe807Dddb074639cD9fA61b47676c064fc50D62C,
			mix_digest: 0x0000000000000000000000000000000000000000000000000000000000000000,
			nonce: 0x0000000000000000,
			number: 0x759597,
			parent_hash: 0x6eba69cc82c3119fe62b59628ae72cafe4175b0cd7619a0ac5b71df4f9ce0883,
			receipts_root: 0x21baad2d37eadd8c0f0c83c4108eab23caf12898ce93075308491ecbf5ae1827,
			uncle_hash: 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347,
			state_root: 0xb1c2730f2b8d4e2db3b1882a4a3535b40eccdb732193e5b111b135c3d7e66693,
			timestamp: 0x60ac73a4,
			transactions_root: 0xe1069870eb63ec670bc9b85a5686d7a168623967d3881f29be150d0515f16ea4
        });
        headers[8] = BSCHeader({
            difficulty: 0x2,
			extra_data: hex'd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b72701c6e8c84e316e4666f356e16f65bde5e7449c7de58937d8515b0a28178b861abfca923a533869b8a05f452f097d209f614553bf5165e9d0c4346ae8b4d47700',
			gas_limit: 0x3938700,
			gas_used: 0xf112c9,
			log_bloom: hex'0f313a2b5e1c52318a8a33508433d3ceefa94b2e9f1f42d069528da2e03805bacb2ad33633f5330445d954f44a99d7313e5d8d859e9a212b2411ad7fa02533c40df2ae406396ba6a21106679a0a300bd2c98092611643c52f5b4a160d7b64f4c7db83aff8fabe1c5430873c0a322f8e5cc59e2778f8bf7f09df159f40c6974e252ec0d7f4e1646d0f884e510601808d8a2e6458d5663cce931ae26d7e611e8f39a10862f76cb94cb79245b3e0f6eb62a0e05097859cc9af04b61de38816140a430e21c6386241227a098239399d372857d5528ba04e508320251405b5027f75512d054cb6624d92a2b68116923ad8f21393c2528e4eadc60206269d49a888ae1',
			coinbase: 0xce2FD7544e0B2Cc94692d4A704deBEf7bcB61328,
			mix_digest: 0x0000000000000000000000000000000000000000000000000000000000000000,
			nonce: 0x0000000000000000,
			number: 0x759598,
			parent_hash: 0x5679a2023347a64daa76f125ae9cea4e97e544f6cde29ea86dbf5634a6825778,
			receipts_root: 0xecd39a15083ea7579eb519681139ce8cee80bf715c92cb14fe3dfae520bc5623,
			uncle_hash: 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347,
			state_root: 0xc80f94f0a82431833bca14dda51ce044f295c51af09858e79b2042a921329e8c,
			timestamp: 0x60ac73a7,
			transactions_root: 0x573883fc0ef9c5801e861305f5fb232a5b242a221ce4379860a9620adb84d9fc
        });
        headers[9] = BSCHeader({
			difficulty: 0x2,
			extra_data: hex'd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b7edbebc7411171a042634750ea85596f260205c95bbdae2676e4e0e6874f613581e171c0ea142e12eb5e361f84acc9c89e37337fb2475f108157d160e5335763101',
			gas_limit: 0x3938700,
			gas_used: 0x13deda4,
			log_bloom: hex'64bb86391978f01d827d0950929d98f1ac08aa149687c13954fa6e46a0202850809ed33b440413c45f1a57e58e29410ab847b5f2062800fb13900af63a2794cc3cd34df6f01164dfa38ba24a80e47978e29129683af5c8129cffbb67c6f69d44581f9aacef0fe0c95a18445b506ba8752235c259cc87364a94b98531542004fa38c2b865a9b2538536cc85d008822884417e742540339918f195467e1aa0ad12afadc43d445a90d8e40ec77dd31ead3eae0c199cd9c03de40d661e2d2cb0cb10b98e7db67140458280021110006331e7e83400b1c0648135185104b7180ead360afbd5bd50a5653ec1e1195d4860160868981798c5cfd7773fa8474cbd8880f4',
			coinbase: 0xe2d3A739EFFCd3A99387d015E260eEFAc72EBea1,
			mix_digest: 0x0000000000000000000000000000000000000000000000000000000000000000,
			nonce: 0x0000000000000000,
			number: 0x759599,
			parent_hash: 0xc81cf1dcd5063c2f63884ffcffdbda41e59bcd5bae48b2a4bda179b72114d341,
			receipts_root: 0x71588d92ee27d509d1e6870e4c108395472d11cddb44b9aed47bf5248a78a787,
			uncle_hash: 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347,
			state_root: 0x9700f54de3fe8393aa76fcc32a9f6ddc9cb9deb21200f220769ba9e6aaa855ff,
			timestamp: 0x60ac73aa,
			transactions_root: 0x958be68fefd51a3e35133cd9711a5bde2e8c3b9599de17c58ef0893dc67193ec
        });
        headers[10] = BSCHeader({
            difficulty: 0x2,
			extra_data: hex'd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b7732a46744f6bbba56b13739737d70abbb03eca14dd199115afc1851dee74e60259d2f9927baea69d1ad824763fa28f272b5bb91d45059f86fa61fa1b4d8a5c6901',
			gas_limit: 0x38ff37a,
			gas_used: 0x193d181,
			log_bloom: hex'7cbd4faffffff7bccbfcf8629521c8ee58a82fd3de3de3e957c58d5794d28995a36cfdb72797f340f95890e27bdf1f771a570fdfd3daf46b2b16f367762f367726fa77d7d91743fe1b5f56e9a0b9b237ff938f385f4f4c56d5b5b28082f22f196e5bdbfdaf1afc10f65ad3df126af80bbb75e37ddf8aff7806b5c43f0e5850cac6ed33ffcc2bf58938f4f608aabefb9fa0aceddf677ad9fb7daf767f6610edd9cbc04c4fdc54a3f9ff7ccb15db7ef6723f0dcbe81fe494f8bb6a8fbf6481e4f5709f7faf6adca21f63b9c26a197ab60f7bc5c5b1916446321a116aaa3deeec66d4765dffa22165ae09687d5a5844831a76bdc5b857dfcee3a2f9a45eafaa87e5',
			coinbase: 0xE9AE3261a475a27Bb1028f140bc2a7c843318afD,
			mix_digest: 0x0000000000000000000000000000000000000000000000000000000000000000,
			nonce: 0x0000000000000000,
			number: 0x75959a,
			parent_hash: 0xa8c0db3c4c73c66009e8eab935096b3c4027fbf036e27f849cf6858621a16a4a,
			receipts_root: 0x4c1fd767550a855ffb24756fcde53408dd989dbff961115bf80cc0cdb610b81b,
			uncle_hash: 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347,
			state_root: 0xb978d927bcb58e884b86b1144a85bc2ba336a827ce1bd77c9995cb3a376a6d56,
			timestamp: 0x60ac73ad,
			transactions_root: 0x11736117a52862926a62053b793cfb8a0e02ca668b9c3299134aaa17fde9bee5
        });
        return headers;
    }

    function build_expected_signers() internal pure returns (address[] memory) {
        address[] memory expected_signers = new address[](21);
        expected_signers[0]  = 0x2465176C461AfB316ebc773C61fAEe85A6515DAA;
        expected_signers[1]  = 0x295e26495CEF6F69dFA69911d9D8e4F3bBadB89B;
        expected_signers[2]  = 0x29a97C6EfFB8A411DABc6aDEEfaa84f5067C8bbe;
        expected_signers[3]  = 0x2D4C407BBe49438ED859fe965b140dcF1aaB71a9;
        expected_signers[4]  = 0x3f349bBaFEc1551819B8be1EfEA2fC46cA749aA1;
        expected_signers[5]  = 0x4430b3230294D12c6AB2aAC5C2cd68E80B16b581;
        expected_signers[6]  = 0x685B1ded8013785d6623CC18D214320b6Bb64759;
        expected_signers[7]  = 0x70F657164e5b75689b64B7fd1fA275F334f28e18;
        expected_signers[8]  = 0x72b61c6014342d914470eC7aC2975bE345796c2b;
        expected_signers[9]  = 0x7AE2F5B9e386cd1B50A4550696D957cB4900f03a;
        expected_signers[10] = 0x8b6C8fd93d6F4CeA42Bbb345DBc6F0DFdb5bEc73;
        expected_signers[11] = 0x9bB832254BAf4E8B4cc26bD2B52B31389B56E98B;
        expected_signers[12] = 0x9F8cCdaFCc39F3c7D6EBf637c9151673CBc36b88;
        expected_signers[13] = 0xa6f79B60359f141df90A0C745125B131cAAfFD12;
        expected_signers[14] = 0xB8f7166496996A7da21cF1f1b04d9B3E26a3d077;
        expected_signers[15] = 0xBe807Dddb074639cD9fA61b47676c064fc50D62C;
        expected_signers[16] = 0xce2FD7544e0B2Cc94692d4A704deBEf7bcB61328;
        expected_signers[17] = 0xe2d3A739EFFCd3A99387d015E260eEFAc72EBea1;
        expected_signers[18] = 0xE9AE3261a475a27Bb1028f140bc2a7c843318afD;
        expected_signers[19] = 0xea0A6E3c511bbD10f4519EcE37Dc24887e11b55d;
        expected_signers[20] = 0xee226379dB83CfFC681495730c11fDDE79BA4c0C;
        return expected_signers;
    }

    function build_checkpoint() internal pure returns (BSCHeader memory header) {
        header = BSCHeader({
            difficulty: 0x2,
			extra_data: hex'd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b72465176c461afb316ebc773c61faee85a6515daa295e26495cef6f69dfa69911d9d8e4f3bbadb89b29a97c6effb8a411dabc6adeefaa84f5067c8bbe2d4c407bbe49438ed859fe965b140dcf1aab71a93f349bbafec1551819b8be1efea2fc46ca749aa14430b3230294d12c6ab2aac5c2cd68e80b16b581685b1ded8013785d6623cc18d214320b6bb6475970f657164e5b75689b64b7fd1fa275f334f28e1872b61c6014342d914470ec7ac2975be345796c2b7ae2f5b9e386cd1b50a4550696d957cb4900f03a8b6c8fd93d6f4cea42bbb345dbc6f0dfdb5bec739bb832254baf4e8b4cc26bd2b52b31389b56e98b9f8ccdafcc39f3c7d6ebf637c9151673cbc36b88a6f79b60359f141df90a0c745125b131caaffd12b8f7166496996a7da21cf1f1b04d9b3e26a3d077be807dddb074639cd9fa61b47676c064fc50d62cce2fd7544e0b2cc94692d4a704debef7bcb61328e2d3a739effcd3a99387d015e260eefac72ebea1e9ae3261a475a27bb1028f140bc2a7c843318afdea0a6e3c511bbd10f4519ece37dc24887e11b55dee226379db83cffc681495730c11fdde79ba4c0c675b589d9452d45327429ff925359ca25b1cc0245ffb869dbbcffb5a0d3c72f103a1dcb28b105926c636747dbc265f8dda0090784be3febffdd7909aa6f416d200',
			gas_limit: 0x391a17f,
			gas_used: 0x151a7b2,
			log_bloom: hex'4f7a466ebd89d672e9d73378d03b85204720e75e9f9fae20b14a6c5faf1ca5f8dd50d5b1077036e1596ef22860dca322ddd28cc18be6b1638e5bbddd76251bde57fc9d06a7421b5b5d0d88bcb9b920adeed3dbb09fd55b16add5f588deb6bcf64bbd59bfab4b82517a1c8fc342233ba17a394a6dc5afbfd0acfc443a4472212640cf294f9bd864a4ac85465edaea789a007e7f17c231c4ae790e2ced62eaef10835c4864c7e5b64ad9f511def73a0762450659825f60ceb48c9e88b6e77584816a2eb57fdaba54b71d785c8b85de3386e544ccf213ecdc942ef0193afae9ecee93ff04ff9016e06a03393d4d8ae14a250c9dd71bf09fee6de26e54f405d947e1',
			coinbase: 0x72b61c6014342d914470eC7aC2975bE345796c2b,
			mix_digest: 0x0000000000000000000000000000000000000000000000000000000000000000,
			nonce: 0x0000000000000000,
			number: 0x759590,
			parent_hash: 0x898c926e404409d6151d0e0ea156770fdaa2b31f8115b5f20bcb1b6cb4dc34c3,
			receipts_root: 0x04aea8f3d2471b7ae64bce5dde7bb8eafa4cf73c65eab5cc049f92b3fda65dcc,
			uncle_hash: 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347,
			state_root: 0x5d03a66ae7fdcc6bff51e4c0cf40c6ec2d291090bddd9073ca4203d84b099bb9,
			timestamp: 0x60ac738f,
			transactions_root: 0xb3db66bc49eac913dbdbe8aeaaee891762a6c5c28990c3f5f161726a8cb1c41d
        });
    }

    function build_genesis_header() internal pure returns (BSCHeader memory header) {
        header = BSCHeader({
            difficulty: 0x2,
            extra_data: hex'd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b72465176c461afb316ebc773c61faee85a6515daa295e26495cef6f69dfa69911d9d8e4f3bbadb89b29a97c6effb8a411dabc6adeefaa84f5067c8bbe2d4c407bbe49438ed859fe965b140dcf1aab71a93f349bbafec1551819b8be1efea2fc46ca749aa14430b3230294d12c6ab2aac5c2cd68e80b16b581685b1ded8013785d6623cc18d214320b6bb6475970f657164e5b75689b64b7fd1fa275f334f28e1872b61c6014342d914470ec7ac2975be345796c2b7ae2f5b9e386cd1b50a4550696d957cb4900f03a8b6c8fd93d6f4cea42bbb345dbc6f0dfdb5bec739bb832254baf4e8b4cc26bd2b52b31389b56e98b9f8ccdafcc39f3c7d6ebf637c9151673cbc36b88a6f79b60359f141df90a0c745125b131caaffd12b8f7166496996a7da21cf1f1b04d9b3e26a3d077be807dddb074639cd9fa61b47676c064fc50d62cce2fd7544e0b2cc94692d4a704debef7bcb61328e2d3a739effcd3a99387d015e260eefac72ebea1e9ae3261a475a27bb1028f140bc2a7c843318afdea0a6e3c511bbd10f4519ece37dc24887e11b55dee226379db83cffc681495730c11fdde79ba4c0c0670403d7dfc4c816a313885fe04b850f96f27b2e9fd88b147c882ad7caf9b964abfe6543625fcca73b56fe29d3046831574b0681d52bf5383d6f2187b6276c100',
            gas_limit: 0x38ff37a,
            gas_used: 0x1364017,
            log_bloom: hex'2c30123db854d838c878e978cd2117896aa092e4ce08f078424e9ec7f2312f1909b35e579fb2702d571a3be04a8f01328e51af205100a7c32e3dd8faf8222fcf03f3545655314abf91c4c0d80cea6aa46f122c2a9c596c6a99d5842786d40667eb195877bbbb128890a824506c81a9e5623d4355e08a16f384bf709bf4db598bbcb88150abcd4ceba89cc798000bdccf5cf4d58d50828d3b7dc2bc5d8a928a32d24b845857da0b5bcf2c5dec8230643d4bec452491ba1260806a9e68a4a530de612e5c2676955a17400ce1d4fd6ff458bc38a8b1826e1c1d24b9516ef84ea6d8721344502a6c732ed7f861bb0ea017d520bad5fa53cfc67c678a2e6f6693c8ee',
            coinbase: 0xE9AE3261a475a27Bb1028f140bc2a7c843318afD,
            mix_digest: 0x0000000000000000000000000000000000000000000000000000000000000000,
            nonce: 0x0000000000000000,
            number: 0x7594c8,
            parent_hash: 0x5cb4b6631001facd57be810d5d1383ee23a31257d2430f097291d25fc1446d4f,
            receipts_root: 0x1bfba16a9e34a12ff7c4b88be484ccd8065b90abea026f6c1f97c257fdb4ad2b,
            uncle_hash: 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347,
            state_root: 0xa6cd7017374dfe102e82d2b3b8a43dbe1d41cc0e4569f3dc45db6c4e687949ae,
            timestamp: 0x60ac7137,
            transactions_root: 0x657f5876113ac9abe5cf0460aa8d6b3b53abfc336cea4ab3ee594586f8b584ca
        });
    }
}

contract ParliaWrapper is BSCLightClient {
    constructor(uint64 chain_id, uint64 period, BSCHeader memory header) BSCLightClient(chain_id, period, header) {}

    function recover_creator(BSCHeader memory header) public view returns (address) {
        return _recover_creator(header);
    }

    function extract_authorities(bytes memory extra_data) public pure returns (address[] memory) {
        return _extract_authorities(extra_data);
    }

    function hash_block(BSCHeader memory header) public pure returns (bytes32) {
        return hash(header);
    }
}
