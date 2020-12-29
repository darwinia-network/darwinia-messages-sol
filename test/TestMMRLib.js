// const MMRWrapper = artifacts.require('MMRWrapper');
// const MMR = artifacts.require('MMR');


const { expect, use, should } = require('chai');
const { solidity } = require("ethereum-waffle");

const web3 = require('web3');
use(require('chai-bn')(web3.utils.BN));
use(require('chai-as-promised'));
should();
use(solidity);

const leafHashs = [
  '0x34f61bfda344b3fad3c3e38832a91448b3c613b199eb23e5110a635d71c13c65',
  '0x70d641860d40937920de1eae29530cdc956be830f145128ebb2b496f151c1afb',
  '0x12e69454d992b9b1e00ea79a7fa1227c889c84d04b7cd47e37938d6f69ece45d',
  '0x3733bd06905e128d38b9b336207f301133ba1d0a4be8eaaff6810941f0ad3b1a',
  '0x3d7572be1599b488862a1b35051c3ef081ba334d1686f9957dbc2afd52bd2028',
  '0x2a04add3ecc3979741afad967dfedf807e07b136e05f9c670a274334d74892cf',
  "0xc58e247ea35c51586de2ea40ac6daf90eac7ac7b2f5c88bbc7829280db7890f1"
]

/**
 * Merkle Mountain Range Tree
 * MMR
 */
describe('MerkleMountainRange', (accounts) => {
  let mmrLib;
  let mmrWrapper;
  let res;

  before(async () => {
    const MMR = await ethers.getContractFactory("MMR");
    mmrLib = await MMR.deploy();
    await mmrLib.deployed();

    MMRWrapper = await ethers.getContractFactory(
      'MMRWrapper',
      {
        libraries: {
          // MMR: mmrLib.address
        }
      }
    );

    mmrWrapper = await MMRWrapper.deploy();
    await mmrWrapper.deployed();

    console.log('MMR Tree : 5 |                             31');
    console.log('           4 |             15                                 30                                    46');
    console.log('           3 |      7             14                 22                 29                 38                 45');
    console.log('           2 |   3      6     10       13       18       21        25       28        34        37       41        44       49');
    console.log('           1 | 1  2   4  5   8  9    11  12   16  17    19  20   23  24    26  27   32  33    35  36   39  40    42  43   47  48    50');
    console.log('       width | 1  2   3  4   5  6     7   8    9  10    11  12   13  14    15  16   17  18    19  20   21  22    23  24   25  26    27');
  });
  context('Test pure functions', async () => {
    describe('getChildren()', async () => {
      it('should return 1,2 as children for 3', async () => {
        res = await mmrLib.getChildren(3);
        expect(res.left.toString()).that.equals('1');
        expect(res.right.toString()).that.equals('2');
      });
      it('should return 3,6 as children for 7', async () => {
        res = await mmrLib.getChildren(7);
        expect(res.left.toString()).that.equals('3');
        expect(res.right.toString()).that.equals('6');
      });
      it('should return 22,29 as children for 30', async () => {
        res = await mmrLib.getChildren(30);
        expect(res.left.toString()).that.equals('22');
        expect(res.right.toString()).that.equals('29');
      });
      it('should be reverted for leaves like 1,2,4 (only reverted in javascript evm)', async () => {
        await mmrLib.getChildren(1).should.be.rejected;
        await mmrLib.getChildren(2).should.be.rejected;
        await mmrLib.getChildren(4).should.be.rejected;
      });
      it('get size', async () => {
        res = await mmrLib.getSize(9314);
        expect(res.toString()).that.equals('18623');
      });
    });
    describe('getPeakIndexes()', async () => {
      it('should return [15, 22, 25] for a mmr which width is 14', async () => {
        res = await mmrLib.getPeakIndexes(14);
        expect(res[0].toString()).that.equals('15');
        expect(res[1].toString()).that.equals('22');
        expect(res[2].toString()).that.equals('25');
      });
      it('should return [3] for a mmr which width is 2', async () => {
        res = await mmrLib.getPeakIndexes(2);
        expect(res[0].toString()).that.equals('3');
      });
      it('should return [31, 46, 49, 50] for a mmr which width is 27', async () => {
        res = await mmrLib.getPeakIndexes(27);
        expect(res[0].toString()).that.equals('31');
        expect(res[1].toString()).that.equals('46');
        expect(res[2].toString()).that.equals('49');
        expect(res[3].toString()).that.equals('50');
      });
    });

    describe('hashBranch()', async () => {
      it('should return blake2b(left,right)', async () => {
        let left = '0x34f61bfda344b3fad3c3e38832a91448b3c613b199eb23e5110a635d71c13c65';
        let right = '0x70d641860d40937920de1eae29530cdc956be830f145128ebb2b496f151c1afb';
        // The index in the parameter is unused
        res = await mmrLib.hashBranch(left, right);
        res.should.equal('0x3aafcc7fe12cb8fad62c261458f1c19dba0a3756647fa4e8bff6e248883938be');
      });
    });

    describe('hashLeaf()', async () => {
      it('should return blake2b(data)', async () => {
        res = await mmrLib.hashLeaf('0x70d641860d40937920de1eae29530cdc956be830f145128ebb2b496f151c1afb70d641860d40937920de1eae29530cdc956be830f145128ebb2b496f151c1afb');
        res.should.equal('0x47c886f3d8a8d9969f31111d05a1664457dd1605219fcfc2cf33cc22a3ec09af');
      });
    });

    describe('peakBagging()', async () => {
      it('should return mmr root', async () => {
        res = await mmrLib.peakBagging(7, [
          '0x488e9565547fec8bd36911dc805a7ed9f3d8d1eacabe429c67c6456933c8e0a6',
          '0x50371e8a99e6c118a0719d96185b92c8943db374143f0d8f2df55d4571316cbe',
          '0xc58e247ea35c51586de2ea40ac6daf90eac7ac7b2f5c88bbc7829280db7890f1'
        ]);
        res.should.equal('0x2dee5b87a481a9105cb4b2db212a1d8031d65e9e6e68dc5859bef5e0fdd934b2');
      });
    });

    describe('mountainHeight()', async () => {
      it('should return 3 for its highest peak when the size is less than 12 and greater than 4', async () => {
        for (let i = 5; i < 12; i++) {
          expect(await mmrLib.mountainHeight(i)).that.equal(3);
        }
      });
      it('should return 4 for its highest peak when the size is less than 27 and greater than 11', async () => {
        for (let i = 12; i < 27; i++) {
          expect(await mmrLib.mountainHeight(i)).to.equal(4);
        }
      });
    });
    describe('heightAt()', async () => {
      let firstFloor = [1, 2, 4, 5, 8, 9, 11, 12, 16, 17, 19, 20, 23, 24, 26, 27, 32, 33, 35, 36, 39, 40, 42, 43, 47, 48];
      let secondFloor = [3, 6, 10, 13, 18, 21, 25, 28, 34, 37, 41, 44, 49];
      let thirdFloor = [7, 14, 22, 29, 38, 45];
      let fourthFloor = [15, 30, 46];
      let fifthFloor = [31];
      it('should return 1 as the height of the index which belongs to the first floor', async () => {
        for (let index of firstFloor) {
          expect(await mmrLib.heightAt(index)).that.equals(1);
        }
      });
      it('should return 2 as the height of the index which belongs to the second floor', async () => {
        for (let index of secondFloor) {
          expect(await mmrLib.heightAt(index)).that.equals(2);
        }
      });
      it('should return 3 as the height of the index which belongs to the third floor', async () => {
        for (let index of thirdFloor) {
          expect(await mmrLib.heightAt(index)).that.equals(3);
        }
      });
      it('should return 4 as the height of the index which belongs to the fourth floor', async () => {
        for (let index of fourthFloor) {
          expect(await mmrLib.heightAt(index)).that.equals(4);
        }
      });
      it('should return 5 as the height of the index which belongs to the fifth floor', async () => {
        for (let index of fifthFloor) {
          expect(await mmrLib.heightAt(index)).that.equals(5);
        }
      });
    });
  });

  context('Gas usage test', async () => {
    it.only('testMountainHeight', async() => {
      await mmrWrapper.testMountainHeight(1);
      await mmrWrapper.testMountainHeight(10);
      await mmrWrapper.testMountainHeight(100);
      await mmrWrapper.testMountainHeight(1000);
      await mmrWrapper.testMountainHeight(10000);
      await mmrWrapper.testMountainHeight(100000);
      await mmrWrapper.testMountainHeight(1000000);
      await mmrWrapper.testMountainHeight(10000000);
    })

    it(`Gas usage test`, async () => {

      //       verify 1-7 used 85949 gas
      //       verify 10000-13990 used 202524 gas
      //       verify 192940-200001 used 271689 gas

      // get block header method:
      // const header = await api.rpc.chain.getHeader('block hash');
      // console.log(header.toHex())

      // 1 -> https://crab.subscan.io/block/0
      // 7 -> https://crab.subscan.io/block/7?tab=log Other - mmr_root
      let tx = await mmrWrapper.verifyProof(
        '0x2dee5b87a481a9105cb4b2db212a1d8031d65e9e6e68dc5859bef5e0fdd934b2',
        7,
        5,
        '0x12e69454d992b9b1e00ea79a7fa1227c889c84d04b7cd47e37938d6f69ece45d0c8eef02cec7ce250f8db3770d55181acae6cde8867ce27a0aabc6c2c97d804a832b1f64326f48c9d3f7e6b1f1c90c26020be3fc7fb39e35f7f8b4696c46c5ba1f0c0642414245b50101000000009ce1c80f000000005aa4784476c13899938c32660fe820d6fa69333ed946f7a0b0d24d06a97c8e52c10e2ec216f4c52042696b2f4e4ba6d1e1b5431fdddb6d4007a38445f47e900960de4cf4d407991ddff04ff65a0edca39360c478ef2b3afb76d760a4d0fef50600904d4d52527ddf10d67045173e3a59efafb304495d9a7c84b84f0bc0235470a5345e32535d054241424501018a516c436e6e82690d4bd6a8075563c29a6ad1489445ef50e675bd57ce92b34943bcc2b8008d8c4e6452e136d00d4dc7cadc5a675cd18a589e6b4d3415965b82',
        '0x3733bd06905e128d38b9b336207f301133ba1d0a4be8eaaff6810941f0ad3b1a',
        [
          '0x488e9565547fec8bd36911dc805a7ed9f3d8d1eacabe429c67c6456933c8e0a6',
          '0x9197278f146f85de21a738c806c24e0b18b266d45fc33cbb922e9534ab26dacd'
        ],
        [
          '0x12e69454d992b9b1e00ea79a7fa1227c889c84d04b7cd47e37938d6f69ece45d',
          '0x3aafcc7fe12cb8fad62c261458f1c19dba0a3756647fa4e8bff6e248883938be',
        ]
      )
      let rsp = await tx.wait();
      let testResult = await mmrWrapper.getResult();

      console.log('testResult', testResult);
      // geth Node - verify 1-7 used 128393 gas
      console.log(`verify 1-7 used ${rsp.gasUsed} gas`);

      // 7000 -> https://crab.subscan.io/block/6999
      // 10000 -> https://crab.subscan.io/block/10000?tab=log Other - mmr_root
      tx = await mmrWrapper.verifyProof(
        '0x04c012d3f663112b7990c75f5aa85686a988b4e921c9f228755eb0494bd62f56',
        10000,
        13990,
        '0x7e97f120b837fc887b63dd3015282a81e24982f1c5df7fadb12a478571d8fce25d6d3840f3944fed0116d96585aa8a94d185d1d247348bdb3745c18a638a129051b86878eb8241dd215f7b8880446d9b811999e69390748cc29dec75397b27d4e29e0c0642414245340200000000f0fcc80f0000000000904d4d5252d98e7727f55fc0b166e5991afe4eb8f990b94edb094cf0c329f1c5399bef2a1805424142450101c0f30a70aaaeb8469be059be3aa52eeb88aa2307bdf7a48f71b193a2d79aba0da0e04bda9c00dd7439ecad3ed428bf6f2f0482bea69bf78a3e06544bb0c3298d',
        '0xdeae4db467aa052af33cb3a4ad5aa1069d1c8d974bd18416381668b53962cebb',
        [
          '0x30f3e4a3960d9ead43c1ea633525f093f3df91579ee4c05e6d9e1561eeb893a5',
          '0x8f7da3cfe0c556f25e21c183709a0cee0c705584482c2971d63d54bd1729cd7e'
        ],
        [
          '0x7e97f120b837fc887b63dd3015282a81e24982f1c5df7fadb12a478571d8fce2',
          '0xffc09ec5cb061d801c5f383985c5972a6d61fe9de188d3e39d371f669212c1b2',
          '0x119d189805003a3e220ff8cee8cbfa57f1bed60813167a37e116954e56248cbc',
          '0x7e1da34ada17f6c701542c81ace090b59efe294838a24a4809572e957fa0aaa6',
          '0xe554ef2847b6cf629100f429ae72f67ec6b8286622d5773fc83ad5dc52a00455',
          '0x246417bf2d87a2c52e5d23f9b1b77526ba35638876ba753905bdd82949d8b88e',
          '0xe19ce8884ba884b8c9b253b411160f3c70ac19e64c8de63693af40bc0f557016',
          '0xca5a68547c628431df0df8c5988c559b26506fb064d3e785a2a55967891bbc88',
          '0xd23a47a77e4489f4f9404055698c80b78e6852b478c917361fd072e90dc782bb',
          '0x9df14d647154a18947b5840b7973f8c464fabe820e511f716f0bf928680be58a',
          '0x1bc39b3c5738795825336b5449025f3b20e5c665dcbb6b9e8a1d21354a3940f8',
          '0x42f19c560c737eb06e7a9fa7b027e07a78275517422d5a7bc8bf0dfac28899fd',
          '0xfc7c8a2e0780489f9487f329ddb967865ca00be6a1b2ce292197b349f2319da5'
        ]
      )
      rsp = await tx.wait();
      testResult = await mmrWrapper.getResult();

      console.log('testResult', testResult);
      // geth Node - verify 6999-10000 used 278330 gas
      console.log(`verify 6999-10000 used ${rsp.gasUsed} gas`)
    });
  });

  context('Verify mmr proof', async () => {
    describe('inclusionProof()', async () => {
      it('should return pass true when it receives a valid merkle proof (0-7)', async () => {
        // bytes32 root,
        // uint256 width,
        // uint256 index,
        // bytes memory value,
        // bytes32[] memory peaks,
        // bytes32[] memory siblings
        expect(await mmrLib.inclusionProof(
          '0x2dee5b87a481a9105cb4b2db212a1d8031d65e9e6e68dc5859bef5e0fdd934b2',
          7,
          0,
          '0x00000000000000000000000000000000000000000000000000000000000000000034d4cabbcdf7ad81f7966f17f08608a6dfb87fcd2ec60ee4a14a5e13223c110f03170a2e7597b7b7e3d84c05391d139a62b157e78786d8c082f29dcf4c11131400',
          [
            '0x488e9565547fec8bd36911dc805a7ed9f3d8d1eacabe429c67c6456933c8e0a6',
            '0x9197278f146f85de21a738c806c24e0b18b266d45fc33cbb922e9534ab26dacd'
          ],
          [
            '0x70d641860d40937920de1eae29530cdc956be830f145128ebb2b496f151c1afb',
            '0xbc3653f301c613152cf85bc3af425692b456847ff6371e5c23e4d74eb6f95ff3'
          ]
        )).that.equals(true);
      })

      it('should return pass true when it receives a valid merkle proof (6999-10000)', async () => {
        expect(await mmrLib.inclusionProof(
          '0x04c012d3f663112b7990c75f5aa85686a988b4e921c9f228755eb0494bd62f56',
          10000,
          6999,
          '0x7e97f120b837fc887b63dd3015282a81e24982f1c5df7fadb12a478571d8fce25d6d3840f3944fed0116d96585aa8a94d185d1d247348bdb3745c18a638a129051b86878eb8241dd215f7b8880446d9b811999e69390748cc29dec75397b27d4e29e0c0642414245340200000000f0fcc80f0000000000904d4d5252d98e7727f55fc0b166e5991afe4eb8f990b94edb094cf0c329f1c5399bef2a1805424142450101c0f30a70aaaeb8469be059be3aa52eeb88aa2307bdf7a48f71b193a2d79aba0da0e04bda9c00dd7439ecad3ed428bf6f2f0482bea69bf78a3e06544bb0c3298d',
          [
            '0x30f3e4a3960d9ead43c1ea633525f093f3df91579ee4c05e6d9e1561eeb893a5',
            '0x8f7da3cfe0c556f25e21c183709a0cee0c705584482c2971d63d54bd1729cd7e'
          ],
          [
            '0x7e97f120b837fc887b63dd3015282a81e24982f1c5df7fadb12a478571d8fce2',
            '0xffc09ec5cb061d801c5f383985c5972a6d61fe9de188d3e39d371f669212c1b2',
            '0x119d189805003a3e220ff8cee8cbfa57f1bed60813167a37e116954e56248cbc',
            '0x7e1da34ada17f6c701542c81ace090b59efe294838a24a4809572e957fa0aaa6',
            '0xe554ef2847b6cf629100f429ae72f67ec6b8286622d5773fc83ad5dc52a00455',
            '0x246417bf2d87a2c52e5d23f9b1b77526ba35638876ba753905bdd82949d8b88e',
            '0xe19ce8884ba884b8c9b253b411160f3c70ac19e64c8de63693af40bc0f557016',
            '0xca5a68547c628431df0df8c5988c559b26506fb064d3e785a2a55967891bbc88',
            '0xd23a47a77e4489f4f9404055698c80b78e6852b478c917361fd072e90dc782bb',
            '0x9df14d647154a18947b5840b7973f8c464fabe820e511f716f0bf928680be58a',
            '0x1bc39b3c5738795825336b5449025f3b20e5c665dcbb6b9e8a1d21354a3940f8',
            '0x42f19c560c737eb06e7a9fa7b027e07a78275517422d5a7bc8bf0dfac28899fd',
            '0xfc7c8a2e0780489f9487f329ddb967865ca00be6a1b2ce292197b349f2319da5'
          ]
        )).that.equals(true);
      })

      it('should return pass true when it receives a valid merkle proof (70-101)', async () => {
        // 70 -> https://crab.subscan.io/block/70
        // 101 -> https://crab.subscan.io/block/101?tab=log Other - mmr_root
        (await mmrLib.inclusionProof(
          '0x29ed180cb4c8428168685508c427038f76cd2b4b9c8898d105e196b0b1ac3595',
          101,
          70,
          '0xd3ac39be1d49a3975f7181b72d86acb895d31acfeb4ec9de3fd042aafd519df0190159e2b914d1d39676807d517871a879ebe92e1e8c2223b7eb68111f42c382d422b552da17c652552ed67c8cb6baebc71e8e34b13a20250134d965a1c9f83ce1bb0c0642414245340201000000dfe1c80f0000000000904d4d525262a835c90ac47b16f27beff0324704cfd488a08e9bc5c9ccfb09f0e7446adcd805424142450101300c71278534877ad6a95ecfc6929bdb12483dbaf5cfc667d120a014a0b5e94be5d23c38c06336921fe771a1fdee96bde254decf102a039408df0867757a7488',
          [
            '0x8c45c0b7b305a8ed920299b75ddc3eb7f407f5c144963411b078853948004415',
            '0x7bc44e54405c31c7db124ca49cbf63a85d756ba05986ca1c74ee5ce61f2d72b5',
            '0xebd030ba24fd8c8492542a9f441c88df235f6a29b059f398ff7e55c67c6295f3'
          ],
          [
            '0xb00aed52959b1c0e45e0db5c3d3740431c19ca1bc0b40100154f512eef1846d9',
            '0x9c225c23b552f6225fec08ab74e3e6d6e64cd07bea2e298ee0c99a05b92ecb40',
            '0x806dc73ef689a190f73463868b24d483443601d44d9d01f7cccf52b7192c633a',
            '0x8f1a432c387676d2ecd17d795e80bb8b0187739b689554dee1213947f087daf3',
            '0x182d29e9d15d57bbaa3e44bcee694594aa3c0c487c9c11b84387434970ffc07d'
          ]
        )).should.be.that.equals(true);
      })

      it('should return pass true when it receives a valid merkle proof (3-7)', async () => {
        expect(await mmrLib.inclusionProof(
          '0x2dee5b87a481a9105cb4b2db212a1d8031d65e9e6e68dc5859bef5e0fdd934b2',
          7,
          3,
          '0x12e69454d992b9b1e00ea79a7fa1227c889c84d04b7cd47e37938d6f69ece45d0c8eef02cec7ce250f8db3770d55181acae6cde8867ce27a0aabc6c2c97d804a832b1f64326f48c9d3f7e6b1f1c90c26020be3fc7fb39e35f7f8b4696c46c5ba1f0c0642414245b50101000000009ce1c80f000000005aa4784476c13899938c32660fe820d6fa69333ed946f7a0b0d24d06a97c8e52c10e2ec216f4c52042696b2f4e4ba6d1e1b5431fdddb6d4007a38445f47e900960de4cf4d407991ddff04ff65a0edca39360c478ef2b3afb76d760a4d0fef50600904d4d52527ddf10d67045173e3a59efafb304495d9a7c84b84f0bc0235470a5345e32535d054241424501018a516c436e6e82690d4bd6a8075563c29a6ad1489445ef50e675bd57ce92b34943bcc2b8008d8c4e6452e136d00d4dc7cadc5a675cd18a589e6b4d3415965b82',
          [
            '0x488e9565547fec8bd36911dc805a7ed9f3d8d1eacabe429c67c6456933c8e0a6',
            '0x9197278f146f85de21a738c806c24e0b18b266d45fc33cbb922e9534ab26dacd'
          ],
          [
            '0x12e69454d992b9b1e00ea79a7fa1227c889c84d04b7cd47e37938d6f69ece45d',
            '0x3aafcc7fe12cb8fad62c261458f1c19dba0a3756647fa4e8bff6e248883938be',
          ]
        )).that.equals(true);
      })

      it('should be rejected', async () => {
        expect(mmrLib.inclusionProof(
          '0x2dee5b87a481a9105cb4b2db212a1d8031d65e9e6e68dc5859bef5e0fdd934b2',
          7,
          6,
          '0x12e69454d992b9b1e00ea79a7fa1227c889c84d04b7cd47e37938d6f69ece45d0c8eef02cec7ce250f8db3770d55181acae6cde8867ce27a0aabc6c2c97d804a832b1f64326f48c9d3f7e6b1f1c90c26020be3fc7fb39e35f7f8b4696c46c5ba1f0c0642414245b50101000000009ce1c80f000000005aa4784476c13899938c32660fe820d6fa69333ed946f7a0b0d24d06a97c8e52c10e2ec216f4c52042696b2f4e4ba6d1e1b5431fdddb6d4007a38445f47e900960de4cf4d407991ddff04ff65a0edca39360c478ef2b3afb76d760a4d0fef50600904d4d52527ddf10d67045173e3a59efafb304495d9a7c84b84f0bc0235470a5345e32535d054241424501018a516c436e6e82690d4bd6a8075563c29a6ad1489445ef50e675bd57ce92b34943bcc2b8008d8c4e6452e136d00d4dc7cadc5a675cd18a589e6b4d3415965b82',
          [
            '0x488e9565547fec8bd36911dc805a7ed9f3d8d1eacabe429c67c6456933c8e0a6',
            '0x9197278f146f85de21a738c806c24e0b18b266d45fc33cbb922e9534ab26dacd'
          ],
          [
            '0x12e69454d992b9b1e00ea79a7fa1227c889c84d04b7cd47e37938d6f69ece45d',
            '0x3aafcc7fe12cb8fad62c261458f1c19dba0a3756647fa4e8bff6e248883938be',
          ]
        )).to.be.revertedWith('Hashed peak is invalid');
      })
    });
  });
});
