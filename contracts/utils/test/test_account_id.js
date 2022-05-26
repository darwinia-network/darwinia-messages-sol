const { expect, use } = require('chai');
const { solidity }  = require("ethereum-waffle");

use(solidity);

describe('AccountIdTest', function (accounts) {

    before(async () => {
        AccountIdTest = await ethers.getContractFactory("AccountIdTest",
        {
          libraries: {
            
          }
        });
        accountIdTest = await AccountIdTest.deploy();
        await accountIdTest.deployed();
    });

    it('fromAddress', async() => {
        await accountIdTest.testFromAddress();
    })

    it('testDeriveEthereumAddressFromDvmAccountId', async() => {
        await accountIdTest.testDeriveEthereumAddressFromDvmAccountId();
    })

    it('testDeriveEthereumAddressFromNormalAccountId', async() => {
        await accountIdTest.testDeriveEthereumAddressFromNormalAccountId();
    })
});
