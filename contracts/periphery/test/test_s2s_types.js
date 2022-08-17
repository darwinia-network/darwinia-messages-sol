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

    it('testGetLastRelayerFromVec', async() => {
        await typesTest.testGetLastRelayerFromVec();
    })
    
    it('testDecodeOutboundLaneData', async() => {
        await typesTest.testDecodeOutboundLaneData();
    })

    it('testDecodeInboundLaneData', async() => {
        await typesTest.testDecodeInboundLaneData();
    })

    it('testGetLastUnrewardedRelayerFromInboundLaneData', async() => {
        await typesTest.testGetLastUnrewardedRelayerFromInboundLaneData();
    })

    it('testBitVecU8', async() => {
        await typesTest.testBitVecU8();
    })
});
