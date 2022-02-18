module.exports = {
  types: {
    VersionedCommitment: {
      _enum: {
        V0: null,
        V1: 'BeefySignedCommitment'
      }
    },
    BeefyCommitment: {
      payload: 'BeefyPayloadHash',
      blockNumber: 'u32',
      validatorSetId: 'u64'
    },
    BeefySignedCommitment: {
      commitment: 'BeefyCommitment',
      signatures: 'Vec<Option<EcdsaSignature>>'
    },
    BeefyNextAuthoritySet: {
      id: 'u64',
      len: 'u32',
      root: 'H256'
    },
    BeefyPayloadHash: 'Vec<([u8; 2], Vec<u8>)>',
    BeefyPayload: {
      network: '[u8; 32]',
      mmr: 'H256',
      messageRoot: 'H256',
      nextValidatorSet: 'Vec<u8>'
    },
    EcdsaSignature: {
      b: 'BitVec',
      i: 'u32',
      s: '[u8; 65]'
    }
  }
}
