const { expect, use } = require('chai');
const { solidity }  = require("ethereum-waffle");

use(solidity);

describe('TestDarwiniaLib', function (accounts) {

    before(async () => {
        Test = await ethers.getContractFactory("DarwiniaLibTest",
        {
          libraries: {}
        });
        test = await Test.deploy();
        await test.deployed();
    });

    it('testBuildCallTransactThroughSigned', async() => {
        await test.testBuildCallTransactThroughSigned();
    })
});
