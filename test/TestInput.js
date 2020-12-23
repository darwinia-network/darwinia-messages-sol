const { expect, use, should } = require('chai');
const { solidity } = require("ethereum-waffle");
const BigNumber = web3.BigNumber;

use(solidity);
require("chai")
  .use(require("chai-as-promised"))
  .use(require("chai-bignumber")(BigNumber))
  .should();

describe('inputTest', function (accounts) {

  before(async () => {

    InputTest = await ethers.getContractFactory("InputTest");

    inputTest = await InputTest.deploy();
    await inputTest.deployed();
  });

  it('inputTest', async () => {
    await inputTest.testToBytes32();
    await inputTest.testToBytesN();
  })

  it('testToBytes32Revert', async () => {
    await expect(inputTest.testToBytes32Revert()).to.be.revertedWith('Input: Out of range');
  })
});
