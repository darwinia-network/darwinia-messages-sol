const { expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const chai = require("chai");

chai.use(solidity);

describe('hashTest', function (accounts) {

  before(async () => {
      HashTest = await ethers.getContractFactory("HashTest",
      {
        libraries: {
          
        }
      });
      hashTest = await HashTest.deploy();
      await hashTest.deployed();
  });

  it('testBlake2b128', async () => {
    await hashTest.testBlake2b128();
  });

  it('testBlake2b128Concat', async () => {
    await hashTest.testBlake2b128Concat();
  });

});
