const { expect, use } = require('chai');
const { solidity }  = require("ethereum-waffle");

use(solidity);

describe('TestPalletEthereumXcmTest', function (accounts) {

    before(async () => {
        PalletEthereumXcmTest = await ethers.getContractFactory("PalletEthereumXcmTest",
        {
          libraries: {
          }
        });
        palletEthereumXcmTest = await PalletEthereumXcmTest.deploy();
        await palletEthereumXcmTest.deployed();
    });

    it('testAccessListType', async() => {
        await palletEthereumXcmTest.testAccessListType();
    })

    it('testEncodeTransactCall', async() => {
        await palletEthereumXcmTest.testEncodeTransactCall();
    })

    it('testEncodeTransactCall2', async() => {
        await palletEthereumXcmTest.testEncodeTransactCall2();
    })
});
