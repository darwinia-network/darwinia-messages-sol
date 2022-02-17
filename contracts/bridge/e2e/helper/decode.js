const { TypeRegistry, createType } = require('@polkadot/types')
const key = require('./types')

const registry = new TypeRegistry();

registry.register(key.types)

module.exports.decodeJustification = function decodeJustification(j) {
  return createType(registry, 'VersionedCommitment', j)
}
