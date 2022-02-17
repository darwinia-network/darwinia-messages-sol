const { TypeRegistry, createType } = require('@polkadot/types')
const key = require('./types')

const registry = new TypeRegistry();

registry.register(key.types)

const a = createType(registry, 'VersionedCommitment', '0x01046462809395314ca21ea6504bdc977e842537a7cb605c6693ee7cebbbed581430446d59f90800000000000000000000048001000000043d31122e484b913210d781135062f842ba2f9b285d0fc18dd00c1f8e8219c7321e4fb39bf41c046c42617e72fbf1af7fe3730c24d676803549e0dffcc18c418201')
console.log(a.toString())
