const { expect, use } = require('chai');
const { solidity }  = require("ethereum-waffle");

use(solidity);

describe('ScaleCodecTest', function (accounts) {

    before(async () => {
        Scale = await ethers.getContractFactory("Scale");
        scale = await Scale.deploy();
        await scale.deployed();

        ScaleTest = await ethers.getContractFactory("ScaleTest",
        {
          libraries: {
            // Scale: scale.address
          }
        });
        scaleTest = await ScaleTest.deploy();
        await scaleTest.deployed();
        

        ScaleCodecTest = await ethers.getContractFactory("ScaleCodecTest",
        {
          libraries: {
            
          }
        });
        scaleCodecTest = await ScaleCodecTest.deploy();
        await scaleCodecTest.deployed();

        ScaleTypesTest = await ethers.getContractFactory("ScaleTypesTest",
        {
          libraries: {
            
          }
        });
        scaleTypesTest = await ScaleTypesTest.deploy();
        await scaleTypesTest.deployed();
    });

    it('encodeUintCompact', async() => {
        await scaleCodecTest.testEncodeUintCompact_SingleByte();
        await scaleCodecTest.testEncodeUintCompact_TwoByte();
        await scaleCodecTest.testEncodeUintCompact_FourByte();
        await scaleCodecTest.testEncodeUintCompact_Big();
    })

    it('encodeUnlockFromRemoteCall', async() => {
        await scaleTypesTest.testEncodeS2SBackingUnlockFromRemoteCall();
    })

    it('encodeSystemRemarkCall', async() => {
        await scaleTypesTest.testEncodeSystemRemarkCall();
    })

    it('encodeBalancesTransferCall', async() => {
        await scaleTypesTest.testEncodeBalancesTransferCall();
    })

    // it('ScaleTest', async() => {
    //     await scaleTest.testDecodeReceiptProof()
    // })

    // it('ScaleTest decodeVec', async () => {
    //   await scaleTest.testDecodeU32();
    //   await scaleTest.testDecodeAccountId();
    //   await scaleTest.testDecodeAccountId2();
    //   await scaleTest.testDecodeBalance();
    //   await scaleTest.testDecodeBalance1();
    //   await scaleTest.testDecodeBalance2();
    //   await scaleTest.testDecodeBalance3();
    //   await scaleTest.testDecodeLockEvents();
    //   await scaleTest.testDecodeEthereumAddress();
    //   await scaleTest.testDecodeAuthorities();
    //   await scaleTest.testDecodeMMRRoot();
    //   await scaleTest.testDecodeStateRootFromBlockHeader();
    //   await scaleTest.testDecodeBlockNumberFromBlockHeader();
    //   await scaleTest.testHackDecodeMMRRootAndDecodeAuthorities();
      
    // })

    // it('CompactMerkleProofTest testCompactMerkleProofTest', async () => {
    //     await compactMerkleProofTest.testSimplePairVerifyProof()
    //     await compactMerkleProofTest.testPairVerifyProof()
    //     await compactMerkleProofTest.testPairsVerifyProof()

    //     await compactMerkleProofTest.test_decode_leaf()
    //     await compactMerkleProofTest.test_encode_leaf()
    //     await compactMerkleProofTest.test_decode_branch()
    //     await compactMerkleProofTest.test_encode_branch()
    // })
});
