const { expect, use } = require('chai');
const { solidity } = require("ethereum-waffle");
const { keccakFromHexString, keccak256 } = require("ethereumjs-util");
const { MerkleMountainRange } = require("merkletreejs")

use(solidity);

const hashFn = (x) => { return x }


const hashLeaf = (index, dataHash) => {
  return dataHash
}

const peakBagging = (size, peaks) => {
  let hash = peaks[peaks.length-1]
  for(let i = peaks.length-1; i >=1; i--){
    let l = peaks[i-1]
    hash = ethers.utils.solidityKeccak256(["bytes32", "bytes32"], [hash, l])
  }
  return hash
}

const hashBranch = (index, left, right) => {
  const hash = ethers.utils.solidityKeccak256(["bytes32", "bytes32"], [left, right])
  return hash
}

const leaves = [
   '0x2a04add3ecc3979741afad967dfedf807e07b136e05f9c670a274334d74892cf',
   '0x46bd20aadd3f873b2bced9f08b5661edfac9e764aec39fb55b52de17d5680df5',
   '0xc58e247ea35c51586de2ea40ac6daf90eac7ac7b2f5c88bbc7829280db7890f1',
]

/**
 * Merkle Mountain Range Tree
 * MMR
 */
describe('MerkleMountainRange', () => {
  let mmrLib;
  let res;

  before(async () => {
    const MMR = await ethers.getContractFactory("KeccakMMRWrapper");
    mmrLib = await MMR.deploy();
    await mmrLib.deployed();

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
       await expect(mmrLib.getChildren(1)).to.revertedWith("VM Exception while processing transaction: revert Not a parent");
       await expect(mmrLib.getChildren(2)).to.revertedWith("VM Exception while processing transaction: revert Not a parent");
       await expect(mmrLib.getChildren(4)).to.revertedWith("VM Exception while processing transaction: revert Not a parent");
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
      it('should return keccak256(left,right)', async () => {
        let left = '0x34f61bfda344b3fad3c3e38832a91448b3c613b199eb23e5110a635d71c13c65';
        let right = '0x70d641860d40937920de1eae29530cdc956be830f145128ebb2b496f151c1afb';
        // The index in the parameter is unused
        res = await mmrLib.hashBranch(left, right);
        expect(res).to.eq('0x2bad0ff1460a76428ca89a1a5f1ae7f6e5e8073bd5b2298c3d8ab3c65e3ec177')
      });
    });

    describe('hashLeaf()', async () => {
      it('should return (data)', async () => {
        res = await mmrLib.hashLeaf(keccakFromHexString("0x70d641860d40937920de1eae29530cdc956be830f145128ebb2b496f151c1afb70d641860d40937920de1eae29530cdc956be830f145128ebb2b496f151c1afb"));
        expect(res).to.eq("0xacbc20f33b2152670ab4054dccc6bb2b24a01c3656004493c03c3ae0fecba3d8");
      });
    });

    describe('peakBagging()', async () => {
      it('should return mmr root', async () => {
        res = await mmrLib.peakBagging([
          '0x488e9565547fec8bd36911dc805a7ed9f3d8d1eacabe429c67c6456933c8e0a6',
          '0x50371e8a99e6c118a0719d96185b92c8943db374143f0d8f2df55d4571316cbe',
          '0xc58e247ea35c51586de2ea40ac6daf90eac7ac7b2f5c88bbc7829280db7890f1'
        ]);
        expect(res).to.eq('0x48fcacfb11870f24a4baab1975cf3e2daf56c1d217196d571fe1d468e410f4f4')
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
    it('testMountainHeight', async() => {
      await mmrLib.testMountainHeight(1);
      await mmrLib.testMountainHeight(10);
      await mmrLib.testMountainHeight(100);
      await mmrLib.testMountainHeight(1000);
      await mmrLib.testMountainHeight(10000);
      await mmrLib.testMountainHeight(100000);
      await mmrLib.testMountainHeight(1000000);
      await mmrLib.testMountainHeight(10000000);
    })

    it('MMR verification', async () => {
      const tree = new MerkleMountainRange(hashFn, leaves, hashLeaf, peakBagging, hashBranch)
      const root = tree.getHexRoot()
      const index = 2
      const proof = tree.getMerkleProof(index)
      const leaf = leaves[index-1]
      const verified = tree.verify(proof.root, proof.width, index, leaf, proof.peakBagging, proof.siblings)
      expect(verified).to.be.true
      const ret = await mmrLib.verifyProof(
        proof.root,
        proof.width,
        index,
        leaf,
        proof.peakBagging,
        proof.siblings
      ) 
      expect(ret).to.be.true
    });
  });
});
