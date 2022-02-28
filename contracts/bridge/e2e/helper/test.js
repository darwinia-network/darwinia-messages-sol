const { TypeRegistry, createType } = require('@polkadot/types')
const { u8aToHex } = require('@polkadot/util')
const key = require('./types')

const registry = new TypeRegistry();

registry.register(key.types)

// const a = createType(registry, 'VersionedCommitment', '0x010464628075b5855f1b82c0987d260a4a11ee5e52b9067906b33e4c892f4b1c34a09656594100000000000000000000000480010000000449ee3ec7e7f8a308250a0b0e253d9f29000f7ecc5ff9959dff98c9502ca629786153f363d62dfa4c92358fcd0ad897d83a34a6864a9dc1f29967a62985eff48801')
// const a = createType(registry, 'VersionedCommitment', '0x01046462809f3e39dfd6729ef0c7dba725acc380f754ea2f0b67b76b40c6a1222adc1a505228bb1200000000000000000004e0040000000c3c7a2362ca9a54e404d65b26c5f6e1a456f1d8b6a8f57f5020661f9e2ef449a110fadc5e6134035b4c304a1bb10fe792d5daeec96b87d7231826b224b04c4ed90027ddc13b8e4e2eb0fec7cf50ff636bd854df62a6bbf8a0a7d87dd530b042a0cd139b30d78f3ce247eef0f45072cf1dfa2487f56df2a491ea2b087bb86e94aa0400e1d76d0fb6801a3abb29c9aa0842dc2664d615a5c8dd0e0b153c018f9096e46d495f6281004dc98a0469ee05b2fe1cb7762ad76a1d41d5d93c566afa53008f5001')

// console.log(a.toString())
// const c = createType(registry, 'BeefyCommitment', a.toJSON().v1.commitment)
// console.log(c.toJSON())
// console.log(c.toHex())

// const p = new Uint8Array([80, 97, 110, 103, 111, 108, 105, 110, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 176, 77, 165, 2, 250, 80, 226, 210, 74, 139, 93, 78, 174, 147, 2, 87, 212, 88, 170, 182, 46, 145, 50, 1, 228, 171, 87, 217, 4, 74, 232, 134, 160, 157, 221, 90, 101, 148, 137, 224, 127, 33, 139, 31, 186, 126, 38, 9, 71, 228, 40, 38, 71, 197, 119, 115, 209, 25, 186, 49, 56, 137, 191, 1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 161, 206, 141, 248, 21, 23, 150, 171, 96, 21, 126, 12, 96, 117, 163, 164, 204, 23, 9, 39, 177, 177, 252, 15, 51, 189, 224, 226, 116, 232, 243, 152])

// const payload = createType(registry, 'BeefyPayload', u8aToHex(p))
// console.log(payload.toString())

const d = createType(registry, 'ConsensusLog', '0x010c0389411795514af1627765eceffcbd002719f031604fadd7d188e2dc585b4e1afb020a1091341fe5664bfa1782d5e04779689068c916b04cb365ec3153755684d9a103bc9d0ca094bd5b8b3225d7651eac5d18c1c04bf8ae8f8b263eebca4e1410ed0c0100000000000000')
console.log(d.toJSON().authoritiesChange)
