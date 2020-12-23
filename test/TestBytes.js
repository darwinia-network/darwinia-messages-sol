const { expect, use, should } = require('chai');
const { solidity } = require("ethereum-waffle");
const BigNumber = web3.BigNumber;

use(solidity);
require("chai")
  .use(require("chai-as-promised"))
  .use(require("chai-bignumber")(BigNumber))
  .should();

describe('TestBytes', function (accounts) {

  before(async () => {

    Bytes = await ethers.getContractFactory("BytesTest");

    bytesLib = await Bytes.deploy();
    await bytesLib.deployed();
  });

  it('BytesTest', async () => {
    await bytesLib.testToBytes32();
    await bytesLib.testToBytes16();
  })

  it('testToBytes32Revert', async () => {
    await expect(bytesLib.testToBytes32Revert()).to.be.revertedWith('Bytes:: toBytes32: data is to short.');
  })

  it('testToBytes16Revert', async () => {
    await expect(bytesLib.testToBytes16Revert()).to.be.revertedWith('Bytes:: toBytes16: data is to short.');
  })
});
