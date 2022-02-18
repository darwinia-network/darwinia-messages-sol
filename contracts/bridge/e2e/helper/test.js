const { TypeRegistry, createType } = require('@polkadot/types')
const key = require('./types')

const registry = new TypeRegistry();

registry.register(key.types)

const a = createType(registry, 'VersionedCommitment', '0x01046462806436f8f9529ac4a6069b505b31fa080ef0d1381ec16570340135772c006a37bc4d0000000000000000000000048001000000046eb9a93b7471de23d28b5f772386bd77c63a798572405863082989d0902f16412b9108838f7ef162e685154ff710c2fa6c76d9f423981bc58976bebe24c4027101')
console.log(a.toString())
