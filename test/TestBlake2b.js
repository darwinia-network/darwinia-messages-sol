const Blake2bTest = artifacts.require('Blake2bTest.sol');
const TestVectors = require('./blake2-kat.json');

contract('Blake2bTest', function (accounts) {
    let contract;

    before(async () => {
        contract = await Blake2bTest.new();
    });

    // it('smoke', async () => {
    //     let ret = await contract.testOneBlock.call(Buffer.alloc(0));
    //     console.log(111, Buffer.alloc(0).toString())
    //     assert.equal(ret, '0x48c9bdf267e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5d182e6ad7f520e511f6c3e2b8c68059b6bbd41fbabd9831f79217e1319cde05b', 'hash mismatch');
    // });

    it('eip-152 test vector 5', async () => {
        let input = Buffer.from('616263', 'hex');
        let ret = await contract.testOneBlock.call(input);
        assert.equal(ret, '0xba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d17d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923', 'hash mismatch');
    });

    it('blake2b reftest (8 bytes input)', async () => {
        let input = Buffer.from('0001020304050607', 'hex');
        let ret = await contract.testOneBlock.call(input);
        assert.equal(ret, '0xe998e0dc03ec30eb99bb6bfaaf6618acc620320d7220b3af2b23d112d8e9cb1262f3c0d60d183b1ee7f096d12dae42c958418600214d04f5ed6f5e718be35566', 'hash mismatch');
    });

    it('blake2b reftest (25 bytes input)', async () => {
        let input = Buffer.from('000102030405060708090a0b0c0d0e0f101112131415161718', 'hex');
        let ret = await contract.testOneBlock.call(input);
        assert.equal(ret, '0x54e6dab9977380a5665822db93374eda528d9beb626f9b94027071cb26675e112b4a7fec941ee60a81e4d2ea3ff7bc52cfc45dfbfe735a1c646b2cf6d6a49b62', 'hash mismatch');
    });

    it('blake2b reftest (255 bytes input)', async () => {
        let input = Buffer.from('000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfe', 'hex');
        let ret = await contract.testOneBlock.call(input);
        assert.equal(ret, '0x5b21c5fd8868367612474fa2e70e9cfa2201ffeee8fafab5797ad58fefa17c9b5b107da4a3db6320baaf2c8617d5a51df914ae88da3867c2d41f0cc14fa67928', 'hash mismatch');
    });

    // it('equihash n=200 k=9 synthethic', async () => {
    //     let ret = await contract.equihashTestN200K9.call();
    //     assert.equal(ret.toString(), '14394687529728284581040569373478606499820061758322408099941575726000591405977', 'output mismatch');
    //     console.log('Gas usage', await contract.equihashTestN200K9.estimateGas());
    // });

    it('blake2b reference test vectors', async () => {
        for (var i in TestVectors) {
            const testCase = TestVectors[i];
            if (testCase.hash !== 'blake2b' || testCase.key.length !== 0) {
                continue;
            }

            let input = Buffer.from(testCase.in, 'hex');
            let input_length = input.length;
            // Pad with zeroes.
            // FIXME: this should not be needed once the library is finished.
            // if (input_length === 0 || (input_length % 128) !== 0) {
            //     input = Buffer.concat([input, Buffer.alloc(128 - (input_length % 128))]);
            // }
            let ret = await contract.testOneBlock.call(input);
            assert.equal(ret, '0x' + testCase.out, 'hash mismatch');
        }
    });
});