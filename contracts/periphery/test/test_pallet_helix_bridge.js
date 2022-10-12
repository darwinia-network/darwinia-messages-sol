const { expect, use } = require('chai');
const { solidity } = require("ethereum-waffle");

use(solidity);

describe('PalletHelixBridgeTest', function() {

    before(async () => {
        PalletHelixBridgeTest = await ethers.getContractFactory("PalletHelixBridgeTest",
            {
                libraries: {
                }
            });
        palletHelixBridgeTest = await PalletHelixBridgeTest.deploy();
        await palletHelixBridgeTest.deployed();
    });

    it('testEncodeIssueFromRemoteCall', async () => {
        await palletHelixBridgeTest.testEncodeIssueFromRemoteCall();
    })

    it('testEncodeIssueFromRemoteCall2', async () => {
        await palletHelixBridgeTest.testEncodeIssueFromRemoteCall2();
    })

    it('testEncodeHandleIssuingFailureFromRemoteCall', async () => {
        await palletHelixBridgeTest.testEncodeHandleIssuingFailureFromRemoteCall();
    })
});
