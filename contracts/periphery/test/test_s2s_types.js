const { expect, use } = require('chai');
const { solidity }  = require("ethereum-waffle");

use(solidity);

describe('S2STypesTest', function (accounts) {

    before(async () => {
        TypesTest = await ethers.getContractFactory("CommonTypesTest",
        {
          libraries: {
            
          }
        });
        typesTest = await TypesTest.deploy();
        await typesTest.deployed();
    });

    it('testDecodeAndGetLastRelayer', async() => {
        await typesTest.testDecodeAndGetLastRelayer();
    })

});
