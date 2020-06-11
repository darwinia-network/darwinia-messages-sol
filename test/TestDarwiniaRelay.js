const DarwiniaRelay = artifacts.require("DarwiniaRelay");
const MMRWrapper = artifacts.require('MMRWrapper');
// const MMR = artifacts.require('MMR');

contract('DarwiniaRelay', (accounts) => {
  let mmrLib;
  let res;
  before(async () => {
    // mmrLib = await MMR.new();
    // await MMRWrapper.link('MMR', mmrLib.address);
    console.log('MMR Tree : 5 |                             31');
    console.log('           4 |             15                                 30                                    46');
    console.log('           3 |      7             14                 22                 29                 38                 45');
    console.log('           2 |   3      6     10       13       18       21        25       28        34        37       41        44       49');
    console.log('           1 | 1  2   4  5   8  9    11  12   16  17    19  20   23  24    26  27   32  33    35  36   39  40    42  43   47  48    50');
    console.log('       width | 1  2   3  4   5  6     7   8    9  10    11  12   13  14    15  16   17  18    19  20   21  22    23  24   25  26    27');
  });

  // const aaa = {
  //   root:
  //     '0xa6094754328d473e11ab4aa55e04d39d8e5607f3c66fe97f903c66fee9018ed6',
  //   width: '<BN: e>',
  //   peakBagging:
  //     ['0x0dfa92386d2f697ec7fba09c01a9b6c4df4681951519add7ee6086b27cd2f319',
  //       '0x8fd6b87c0343ba19c5d9b3075a699d8171f72df4105ddd9ae05cba5f434d998f',
  //       '0x176cd98f201d2d9af8a47cca45cac4637cc18f86bccf402934ee554046741fb5'],
  //   siblings:
  //     ['0xea53f4f0625edf727a750b721b124e58e2a73f80606ab47601f4493f6b4ca920',
  //       '0x4ee186d69fe539de9b1360cd91b4397168ad20232445a3085917f0461f54acf2',
  //       '0xf1f173a34ecaf6f0f5187732c3a59ff0026a177c0ebf8ce6bc3f973e70adb88d']
  // }

  describe('inclusionProof()', async () => {
    before(async () => {
      // mmr = await MMRWrapper.new();
      // for (let i = 0; i < 3; i++) {
      //   await mmr.append('0x0000');
      // }
    });
    it('should return pass true when it receives a valid merkle proof', async () => {
      const metaCoinInstance = await DarwiniaRelay.deployed();
      let input = Buffer.from('0001020304050607000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', 'hex');
      let ret = await metaCoinInstance.Blake2bHash.call(input, 3);

      assert.equal(ret, '0x3d8c3d594928271f44aad7a04b177154806867bcf918e1549c0bc16f9da2b09b')
// return
      // let index = 2;
      // res = await mmr.getMerkleProof(index);
      // console.log(1111, res)
      // const isInclusionProof = await metaCoinInstance.verifyProof.call(res.root, res.width, index, '0x0000', res.peakBagging, res.siblings);
      // let input = Buffer.from('0001020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', 'hex');
      //   let ret = await metaCoinInstance.Blake2bHash.call(input, 3);
      // console.log(1113, ret)
      // console.log(1112, isInclusionProof)
      // assert.equal(isInclusionProof, true)
    });

    // it('should revert when it receives an invalid merkle proof', async () => {
    //   let index = 27;
    //   res = await mmr.getMerkleProof(index);
    //   // Stored value is 0x0000 not 0x0001
    //   const result = await mmrLib.inclusionProof(res.root, res.width, index, '0x0001', res.peakBagging, res.siblings).should.be.rejected;

    // });
  });




  // 5234f61bfda344b3fad3c3e38832a91448b3c613b199eb23e5110a635d71c13c65
  // 523aafcc7fe12cb8fad62c261458f1c19dba0a3756647fa4e8bff6e248883938be
  // 527ddf10d67045173e3a59efafb304495d9a7c84b84f0bc0235470a5345e32535d
  // 52488e9565547fec8bd36911dc805a7ed9f3d8d1eacabe429c67c6456933c8e0a6
  // 526e0c4ab56e0919a7d45867fcd1216e2891e06994699eb838386189e9abda55f1


  // it('should put 10000 DarwiniaRelay in the first account', async () => {
  //   const metaCoinInstance = await DarwiniaRelay.deployed();
  //   const balance = await metaCoinInstance.getBalance.call(accounts[0]);

  //   assert.equal(balance.valueOf(), 10000, "10000 wasn't in the first account");
  // });
  // it('should call a function that depends on a linked library', async () => {
  //   const metaCoinInstance = await DarwiniaRelay.deployed();
  //   const metaCoinBalance = (await metaCoinInstance.getBalance.call(accounts[0])).toNumber();
  //   const metaCoinEthBalance = (await metaCoinInstance.getBalanceInEth.call(accounts[0])).toNumber();

  //   assert.equal(metaCoinEthBalance, 2 * metaCoinBalance, 'Library function returned unexpected function, linkage may be broken');
  // });
  // it('should send coin correctly', async () => {
  //   const metaCoinInstance = await DarwiniaRelay.deployed();

  //   // Setup 2 accounts.
  //   const accountOne = accounts[0];
  //   const accountTwo = accounts[1];

  //   // Get initial balances of first and second account.
  //   const accountOneStartingBalance = (await metaCoinInstance.getBalance.call(accountOne)).toNumber();
  //   const accountTwoStartingBalance = (await metaCoinInstance.getBalance.call(accountTwo)).toNumber();

  //   // Make transaction from first account to second.
  //   const amount = 10;
  //   await metaCoinInstance.sendCoin(accountTwo, amount, { from: accountOne });

  //   // Get balances of first and second account after the transactions.
  //   const accountOneEndingBalance = (await metaCoinInstance.getBalance.call(accountOne)).toNumber();
  //   const accountTwoEndingBalance = (await metaCoinInstance.getBalance.call(accountTwo)).toNumber();


  //   assert.equal(accountOneEndingBalance, accountOneStartingBalance - amount, "Amount wasn't correctly taken from the sender");
  //   assert.equal(accountTwoEndingBalance, accountTwoStartingBalance + amount, "Amount wasn't correctly sent to the receiver");
  // });
});
