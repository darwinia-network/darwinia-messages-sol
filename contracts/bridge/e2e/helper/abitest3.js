const { ethers } = require("ethers");
const ExecutionLayer = require("../../artifacts/src/truth/eth/ExecutionLayer.sol/ExecutionLayer.json");


(async () => {
  const iface = new ethers.utils.Interface(ExecutionLayer.abi)
  const update = {
    latest_execution_payload_state_root: '0xe55ce819dcd715afb77bac000eb6495ea0dc93e3380501100718403c063a70b0',
    latest_execution_payload_state_root_branch: [
    '0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421',
    '0x89fbf2edd4374bf78f47f697abedbbb3063b0948d4c2c69a715d2664f45ef943',
    '0xb2aced9d410d818440966483a6f23f045146aa4a4d5f25918bff488af24a285f',
    '0x60187b4f101a1533632d9c730a1a419f6b61de9a412e2e33ce18b8f041e0580c',
    '0x0000000000000000000000000000000000000000000000000000000000000000',
    '0xf5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a92759fb4b',
    '0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71',
    '0x221207ac8656532897f09f6e17c05fa2ef1d32cf1cd6187b79c5d0fa7c4ba7f4',
    '0x5e97dd766bf30ee49745229a3790470e642f2dd3b3c8ce13e3f7b4bc6e4b3205'
    ],
  }
  console.log(await iface.encodeFunctionData("import_latest_execution_payload_state_root", [ update ]))
})();
