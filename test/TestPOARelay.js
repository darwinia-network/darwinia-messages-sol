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
      [...Array(n).keys()].map(async i =>
         jsonRpcProvider.send('evm_mine', [])
      )
    );
  };

  const waitNTime =  n => {
     jsonRpcProvider.send('evm_increaseTime', [n])
  };

  let relayConstructor = [
    4,
    '0x488e9565547fec8bd36911dc805a7ed9f3d8d1eacabe429c67c6456933c8e0a6',
    100,
    [
      '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266'
    ],
    [
      '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266',
    ]
  ]

  before(async function() {
    accounts = await ethers.getSigners();
    for (const account of accounts) {
      console.log(account.address);
    }
  });

  before(async () => {
    const MMR = await ethers.getContractFactory("MMR");
    mmrLib = await MMR.deploy();
    await mmrLib.deployed();

    POARelay = await ethers.getContractFactory(
      'POARelay',
      {
        libraries: {
          MMR: mmrLib.address
        }
      }
    );

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
      result = await relay.appendRoot(7, '0x2dee5b87a481a9105cb4b2db212a1d8031d65e9e6e68dc5859bef5e0fdd934b2');
      const mmr = await relay.getMMRRoot(7);
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
      // await time.advanceBlock()
      // let blocknumber = await provider.getBlockNumber();
      // console.log(blocknumber)
      // await waitNTime(100);
      // blocknumber = await provider.getBlockNumber();
      // console.log(blocknumber);
      await waitNTime(10000);
      await waitNBlocks(2);
      await waitNTime(10000);
      await relay.appendRoot(0, '0x0000000000000000000000000000000000000000000000000000000000000001');
      // await(relay.appendRoot(0, '0x0000000000000000000000000000000000000000000000000000000000000001')).should.be.rejected;
      await waitNTime(10000);
      // await relay.appendRoot(8, '0x54be644b5b3291dd9ae9598b49d1f986e4ebd8171d5e89561b2a921764c7b17c');
      // await(relay.appendRoot(8, '0x54be644b5b3291dd9ae9598b49d1f986e4ebd8171d5e89561b2a921764c7b17c')).should.be.rejected;
      // await expectRevert(
      //   relay.appendRoot(0, '0x0000000000000000000000000000000000000000000000000000000000000001'),
      //   'POARelay: The previous one is still pending or no dispute1',
      // );
    });
  })

  // describe('resetRoot', async () => {
  //   it('reset mmr root', async () => {
  //     await relay.updateRoot(5, '0x0000000000000000000000000000000000000000000000000000000000000005');
  //     await relay.updateRoot(6, '0x0000000000000000000000000000000000000000000000000000000000000006');
  //     await relay.resetRoot(5, '0x0000000000000000000000000000000000000000000000000000000000000055');
  //     expect(await relay.getMMR.call(5)).to.be.equal(
  //       '0x0000000000000000000000000000000000000000000000000000000000000055',
  //     );
  //   });

  //   it('paused status', async () => {
  //     await expectRevert(relay.updateRoot(7, '0x0000000000000000000000000000000000000000000000000000000000000007'),
  //       'Pausable: paused.',
  //     );
  //   });

  //   it('unpaused status', async () => {
  //     await relay.unpause();
  //     await relay.updateRoot(8, '0x0000000000000000000000000000000000000000000000000000000000000008');
  //     const mmr = await relay.getMMR.call(8);
  //     assert.equal(mmr, '0x0000000000000000000000000000000000000000000000000000000000000008');
  //   });
  // })
});
