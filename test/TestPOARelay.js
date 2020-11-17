const { expectRevert, time } = require('@openzeppelin/test-helpers');

const {expect, use, should} = require('chai');
const { solidity }  = require("ethereum-waffle");
const pify = require('pify')
const Web3 = require('web3');
use(solidity);

// const Web3Utils = require("web3-utils");
// const BigNumber = web3.BigNumber;

// const web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:8545/"));
var jsonRpcProvider = new ethers.providers.JsonRpcProvider();
const provider = ethers.getDefaultProvider('http://127.0.0.1:8545/');
require("chai")
  .use(require("chai-as-promised"))
  // .use(require("chai-bignumber")(BigNumber))
  .should();

describe('POARelay', () => {
  let mmrLib;
  let relay;
  let blake2b;
  let res;
  let darwiniaRelay;
  let accounts;

  const waitNBlocks = async n => {
    await Promise.all(
      [...Array(n).keys()].map(async i => {
        return await jsonRpcProvider.send('evm_mine', [])
      }   
      )
    );
  };

  const waitNTime =  n => {
     jsonRpcProvider.send('evm_increaseTime', [n])
  };

  let relayConstructor = {};

  before(async () => {
    const MMR = await ethers.getContractFactory("MMR");
    const SimpleMerkleProof = await ethers.getContractFactory("SimpleMerkleProof");
    const [owner, addr1] = await ethers.getSigners();
    accounts = await ethers.getSigners();

    // all test accounts
    for (const account of accounts) {
      console.log(account.address);
    }

    mmrLib = await MMR.deploy();
    simpleMerkleProof = await SimpleMerkleProof.deploy();
    await mmrLib.deployed();
    await simpleMerkleProof.deployed();

    POARelay = await ethers.getContractFactory(
      'POARelay',
      {
        libraries: {
          MMR: mmrLib.address,
          SimpleMerkleProof: simpleMerkleProof.address
        }
      }
    );

    relayConstructor = [
      4,
      '0x488e9565547fec8bd36911dc805a7ed9f3d8d1eacabe429c67c6456933c8e0a6',
      100,
      [await owner.getAddress()],
      [await addr1.getAddress()]
    ]
    
    relay = await POARelay.deploy(...relayConstructor);
    await relay.deployed();
  });

  describe('utils', async () => {
    before(async () => {
      const proof = {
        root: '0xfa36bb3176772b05ba22963825abbfb14379fe87b9a18449ec8175096c345d93',
        width: 7,
        peakBagging: [
          "0x53beeed16718d356e5494ef52332b50d16cf8588f36dd19f29f7d4c404d860be",
          "0xa7df2cb3ecdca703b0471f655de3cefc7ebf943b4d94303c317b06a9dcc6ddcb",
          "0xc58e247ea35c51586de2ea40ac6daf90eac7ac7b2f5c88bbc7829280db7890f1"
        ],
        siblings: [
          '0x70d641860d40937920de1eae29530cdc956be830f145128ebb2b496f151c1afb',
          '0xdfafd69d36c0d7d6cd07bfce7bcf93c5221e9f2fe11ea9df8ff79e1a4750295b'
        ]
      }

      // const isValid = await relay.inclusionProof.call(proof.root, proof.width, 1, '0x00', '0x34f61bfda344b3fad3c3e38832a91448b3c613b199eb23e5110a635d71c13c65', proof.peakBagging, proof.siblings)
      // console.log(isValid)
    });

    it('getReceipt', async () => {
      let result = await relay.getReceipt('0x0d30059ba03a56080d9e46f5452e3a9a8b21fd37c02223284e386f967b88c194', '0x081081035f00d41e5e16056765bc8461851072c9d735031400000000000000608796090000000002000000010000001702e096b1496b056d5e1ee8e9ef272ff74f05e50884a52318adde16b3b5c6655c3f22aaaaf10536d812c7e097f59e7b769e24341830d42d4551a5c0369a588e4e4000e40b54020000000000000000000000000001000000200600c4192700000000000000000000000000000100000017040f99850f381fdfb5b965617619e59ed082a4515c22967c9c1c94621969362aba0071c6090000000000000000000000000000010000000000401b5f1300000000000000c10680ffb9805626b5eeb95364cd35028f6c2e9502e6763c35b49146c3e06eb0fb0c8437e2f5807d6bd45dc0de8a9d3c09ed996173e3228aa1f0c14343e3613600679837c0459e80a1aec849f3a38d7d135fb693c8ea2d30ce711f9de4d6216df3c1a9a1fed7652480f4aa779b91c9584e64e8f414a45415633ddab553b733a8f053ea281665f6e2798037521b6b221966c2e46dadb5ec9f5dd9955bfb6ddc80b7fd2426c8a80b715742807dfc144d3b4073275b82f6e907ec3a2e23734838c9dfd21815d40813f1037bc980257276b52625f532a5b3415084fb91ded52ba117e97209555a8c05054ce5310d80e9e915eca5fb72b66cf72c2e7726f366889ee12e459bb8e4c8db0db83b5b408f80f39c11c55a33b88d079ac377e5fddee82d1c9471f66fb6a28bd3ad96446c983680df791956f0167fb9bed6c0e9fee9de3d6babf3d1152f5deca446dc29a9e9c9fe80d0b26d2c3777a1ff46e46dab9260a54906108d698aa87d6e4a5ebd0d9d9dd416800d5ead5e5c3f67b600edee6ff127a9cdb90fa28f06bc4804ce6dc639c887360b8004815669f5ffdf790a76a75b3b40f700e8bf7d73eb084aaf9dd793eeda3d525269039eaa394eea5630e07c48ae0c9558cef7298d585f0a98fdbe9ce6c55837576c60c7af3850100500000080798651e0861e900ea90d37dbeea088da90fe28b729ad85b33daa3e3b3dcc9c514c5f0684a022a34dd8bfa2baaf44f172b710040180ebbd938d8e0afb593ff42ca3bc9f58af377da287c9f7c380aa508fa6da70e15580ced43296cd3920efab18447ae4ba50dcc5e87a8db36593ee92756cdd9f36b7598082a75959f024cac266849285f69c1ac49da16ee7801ff4f93fd3cfd3563a47bc605f09cce9c888469bb1a0dceaa129672ef8187010437261622503804b0c80feecb9b8cd91aca389352bb80a01c989ade193be7b6361af47238c2974617a1c808294a7635adce51c7ce4f1faa73c37b02852af44ddea9f79eedfea377ce12711801941a755228dfeade556d93ca6af552ca8974fef5d59b56e6ed0083814201fd0800c8012fed6518393bda3231cc9bc889428748a0c4f6e4c832a632469630e203180d80ae17a3fa70e1addb66fd67ff84d2d84c290c73ef9d15d1d748a134d79b15580f732747b5206732f92adaf4f143693558e5cff9d78ae1b2b40040fdcbef859b2048026aa394eea5630e07c48ae0c9558cef780d41e5e16056765bc8461851072c9d7');
      expect(result).that.equal('0x1400000000000000608796090000000002000000010000001702e096b1496b056d5e1ee8e9ef272ff74f05e50884a52318adde16b3b5c6655c3f22aaaaf10536d812c7e097f59e7b769e24341830d42d4551a5c0369a588e4e4000e40b54020000000000000000000000000001000000200600c4192700000000000000000000000000000100000017040f99850f381fdfb5b965617619e59ed082a4515c22967c9c1c94621969362aba0071c6090000000000000000000000000000010000000000401b5f1300000000000000');
    });


    it('decodeCompactU8a 63', async () => {
      let result = await relay.decodeCompactU8aOffset('0xfc');
      expect(result).that.equal(1);
    });

    it('decodeCompactU8a 511', async () => {
      let result = await relay.decodeCompactU8aOffset('0xFD');
      expect(result).that.equal(2);
    });

    it('decodeCompactU8a 0xffff', async () => {
      let result = await relay.decodeCompactU8aOffset('0xFE');
      expect(result).that.equal(4);
    });

    it('decodeCompactU8a 0xfffffff9', async () => {
      let result = await relay.decodeCompactU8aOffset('0x03');
      expect(result).that.equal(5);
    });

    it('decodeCompactU8a 1556177', async () => {
      let result = await relay.decodeCompactU8aOffset('0x46');
      expect(result).that.equal(4);;
    });

    it('block 1', async () => {
      let result = await relay.getStateRootFromBlockHeader(0, '0x00000000000000000000000000000000000000000000000000000000000000000034d4cabbcdf7ad81f7966f17f08608a6dfb87fcd2ec60ee4a14a5e13223c110f03170a2e7597b7b7e3d84c05391d139a62b157e78786d8c082f29dcf4c11131400');
      expect(result).that.equal('0x34d4cabbcdf7ad81f7966f17f08608a6dfb87fcd2ec60ee4a14a5e13223c110f');
    });

    it('block 1556177', async () => {
      result = await relay.getStateRootFromBlockHeader(0, '0xb0209dd32ae874b32f152fc6fe2db8239b661746f010a82aa3389f57a33c659c46fb5e003a95a548cc56b60091f835b0d467bdd0bfff9f1cf5414ae6628f03ce0166ef3580f3f8edfbc56eed5c09443c4a82551a4d312df46208d7664d096001464192de0c0642414245340203000000c032e10f0000000000904d4d52524c7943e36016e64c2c125bb69292e6e2aad9b413149b4d82f5ae5a50bd5d84c5054241424501016aa6ace563323fc7f8a3899d38cb3d821ec079e61befb4d05045fb847eb8b517623dfde6c34ed431bbc9860ac4836164c655d65696126d61c10c47050b47f387');
      expect(result).that.equal('0x3a95a548cc56b60091f835b0d467bdd0bfff9f1cf5414ae6628f03ce0166ef35');
    });

    //mock
    it('block 1073741824', async () => {
      result = await relay.getStateRootFromBlockHeader(0, '0xb0209dd32ae874b32f152fc6fe2db8239b661746f010a82aa3389f57a33c659c03000000403a95a548cc56b60091f835b0d467bdd0bfff9f1cf5414ae6628f03ce0166ef3580f3f8edfbc56eed5c09443c4a82551a4d312df46208d7664d096001464192de00');
      expect(result).that.equal('0x3a95a548cc56b60091f835b0d467bdd0bfff9f1cf5414ae6628f03ce0166ef35');
    });
  });

  describe('getRoot', async () => {
    it('get empty mmr root', async () => {
      const mmr = await relay.getMMRRoot(0);
      expect(mmr).that.equal('0x0000000000000000000000000000000000000000000000000000000000000000');
    });
    it(`get mmr root of width is ${relayConstructor[0]}`, async () => {
      const mmr = await relay.getMMRRoot(relayConstructor[0]);
      expect(mmr).that.equal(relayConstructor[1]);
    });
    it(`get mmr root of width`, async () => {
      const width = await relay.latestWidth.call();
      expect(width).that.equal(relayConstructor[0]);
    });
  })

  describe('updateRoot', async () => {


    it('append mmr root', async () => {
      const [owner, addr1] = await ethers.getSigners();

      // Use a non-relayer account to append root
      await expect(relay.connect(addr1).appendRoot(7, '0x2dee5b87a481a9105cb4b2db212a1d8031d65e9e6e68dc5859bef5e0fdd934b2')).to.be.revertedWith("POARelay: caller is not the relayer or owner");

      result = await relay.appendRoot(7, '0x2dee5b87a481a9105cb4b2db212a1d8031d65e9e6e68dc5859bef5e0fdd934b2');
      const mmr = await relay.getMMRRoot(7);

      // The root with width = 7 is in the candidate stage
      expect(mmr).that.equal('0x0000000000000000000000000000000000000000000000000000000000000000');

      const candidateRoot = await relay.candidateRoot.call();
      expect(candidateRoot.width).that.equal(7);
      expect(candidateRoot.data).that.equal('0x2dee5b87a481a9105cb4b2db212a1d8031d65e9e6e68dc5859bef5e0fdd934b2');
      expect(candidateRoot.dispute).that.equal(false);
    });

    it('current mmr root has not changed', async () => {
      const width = await relay.latestWidth.call();
      const mmr = await relay.getMMRRoot(width);
      expect(mmr).that.equal(relayConstructor[1]);
    });

    it('updateRoot same width', async () => {
      //  The last round of elections did not end
      await expect(relay.appendRoot(10, '0x0000000000000000000000000000000000000000000000000000000000000001')).to.eventually.be.rejectedWith("POARelay: The previous one is still pending or no dispute");
      await waitNTime(101);
      await expect(relay.appendRoot(7, '0x0000000000000000000000000000000000000000000000000000000000000001')).to.eventually.be.rejectedWith("POARelay: A higher block has been confirmed");

      await relay.appendRoot(10, '0xa94bf2a4e0437c236c68675403d980697cf7c9b0f818a622cb40199db5e12cf8');

      const candidateRoot = await relay.candidateRoot.call();
      expect(candidateRoot.width).that.equal(10);
      expect(candidateRoot.data).that.equal('0xa94bf2a4e0437c236c68675403d980697cf7c9b0f818a622cb40199db5e12cf8');
      expect(candidateRoot.dispute).that.equal(false);

      const mmr = await relay.getMMRRoot(7);
      expect(mmr).that.equal('0x2dee5b87a481a9105cb4b2db212a1d8031d65e9e6e68dc5859bef5e0fdd934b2');

      const width = await relay.latestWidth.call();
      expect(width).that.equal(7);

    });

    it('dispute root', async () => {
      const [owner, addr1, addr2] = await ethers.getSigners();
      await expect(relay.connect(addr2).disputeRoot()).to.be.revertedWith('POARelay: caller is not the supervisor or owner');

      await relay.connect(addr1).disputeRoot();

      let candidateRoot = await relay.candidateRoot.call();
      expect(candidateRoot.dispute).that.equal(true);

      await relay.appendRoot(11, '0x587f0b5d3ec8e256320bacd96900d0e484883c7778ca49e05c65c546c31e3aa3');
      candidateRoot = await relay.candidateRoot.call();
      expect(candidateRoot.width).that.equal(11);
      expect(candidateRoot.data).that.equal('0x587f0b5d3ec8e256320bacd96900d0e484883c7778ca49e05c65c546c31e3aa3');
      expect(candidateRoot.dispute).that.equal(false);

      const width = await relay.latestWidth.call();
      expect(width).that.equal(7);

      const mmr = await relay.getMMRRoot(width);
      expect(mmr).that.equal('0x2dee5b87a481a9105cb4b2db212a1d8031d65e9e6e68dc5859bef5e0fdd934b2');

      await waitNTime(101);
    })
  })

  describe('resetRoot', async () => {
    it('reset mmr root', async () => {
      await relay.resetRoot(5, '0x0000000000000000000000000000000000000000000000000000000000000005');
      expect(await relay.getMMRRoot(5)).that.equal(
        '0x0000000000000000000000000000000000000000000000000000000000000005',
      );
    });

    it('paused status', async () => {
      await relay.pause();
      await expect(relay.appendRoot(12, '0x0000000000000000000000000000000000000000000000000000000000000012')).to.be.revertedWith('Pausable: paused');
    });

    it('unpaused status', async () => {
      await relay.unpause();
      await relay.appendRoot(12, '0x0000000000000000000000000000000000000000000000000000000000000012')
    });
  })
});
