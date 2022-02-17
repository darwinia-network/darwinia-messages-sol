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
    EcdsaSignature: '[u8; 70]',
  }
}

registry.register(key.types)

const a = createType(registry, 'VersionedCommitment', '0x01046462809395314ca21ea6504bdc977e842537a7cb605c6693ee7cebbbed581430446d59f90800000000000000000000048001000000043d31122e484b913210d781135062f842ba2f9b285d0fc18dd00c1f8e8219c7321e4fb39bf41c046c42617e72fbf1af7fe3730c24d676803549e0dffcc18c418201')
console.log(a.toString())
