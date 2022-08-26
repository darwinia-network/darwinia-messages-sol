const { expect, use } = require('chai');
const { solidity }  = require("ethereum-waffle");

use(solidity);

describe('TestPalletMessageRouter', function (accounts) {

    before(async () => {
        PalletMessageRouterTest = await ethers.getContractFactory("PalletMessageRouterTest",
        {
          libraries: {
          }
        });
        palletMessageRouterTest = await PalletMessageRouterTest.deploy();
        await palletMessageRouterTest.deployed();
    });

    it('testEncodeVersionedXcmV2', async() => {
        await palletMessageRouterTest.testEncodeVersionedXcmV2();
    })
});
