const { TypeRegistry, createType } = require('@polkadot/types')
const key = require('./types')

const registry = new TypeRegistry();

registry.register(key.types)

function encodeCommitment(c) {
  return createType(registry, 'BeefyCommitment', c)
}

function encodeNextAuthoritySet(c) {
  return createType(registry, 'BeefyNextAuthoritySet', c)
}

function encodeBeefyPayload(c) {
  return createType(registry, 'BeefyPayload', c)
}

module.exports = {
  encodeCommitment,
  encodeBeefyPayload,
  encodeNextAuthoritySet,
}
