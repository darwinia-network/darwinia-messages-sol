const { TypeRegistry, createType } = require('@polkadot/types')

const registry = new TypeRegistry();

const key = {
  types: {
    VersionedCommitment: {
      _enum: {
        V0: null,
        V1: 'BeefySignedCommitment'
      }
    },
    BeefyCommitment: {
      payload: 'BeefyPayload',
      blockNumber: 'u32',
      validatorSetId: 'ValidatorSetId'
    },
    BeefyId: '[u8; 2]',
    Payload: '(BeefyId, Vec<u8>)',
    BeefyIdPayload: 'Vec<Payload>',
    BeefySignedCommitment: {
      commitment: 'BeefyCommitment',
      signatures: 'Vec<Option<EcdsaSignature>>'
    },
    BeefyNextAuthoritySet: {
      id: 'u64',
      len: 'u32',
      root: 'H256'
    },
    BeefyPayload: 'BeefyIdPayload',
    ValidatorSetId: 'u64',
  }
}

registry.register(key.types)

module.exports.decodeJustification = function decodeJustification(j) {
  return createType(registry, 'VersionedCommitment', j)
}
