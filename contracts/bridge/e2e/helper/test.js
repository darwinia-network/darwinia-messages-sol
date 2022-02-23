const { TypeRegistry, createType } = require('@polkadot/types')
const key = require('./types')

const registry = new TypeRegistry();

registry.register(key.types)

const a = createType(registry, 'VersionedCommitment', '0x010464628075b5855f1b82c0987d260a4a11ee5e52b9067906b33e4c892f4b1c34a09656594100000000000000000000000480010000000449ee3ec7e7f8a308250a0b0e253d9f29000f7ecc5ff9959dff98c9502ca629786153f363d62dfa4c92358fcd0ad897d83a34a6864a9dc1f29967a62985eff48801')

console.log(a.toString())
const c = createType(registry, 'BeefyCommitment', a.toJSON().v1.commitment)
console.log(c.toJSON())
console.log(c.toHex())
