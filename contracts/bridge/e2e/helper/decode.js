const { TypeRegistry, createType } = require('@polkadot/types')
const key = require('./types')

const registry = new TypeRegistry();

registry.register(key.types)

function decodeJustification(j) {
  return createType(registry, 'VersionedCommitment', j)
}

function decodeConsensusLog(j) {
  return createType(registry, 'ConsensusLog', j)
}

module.exports = {
  decodeConsensusLog,
  decodeJustification
}
