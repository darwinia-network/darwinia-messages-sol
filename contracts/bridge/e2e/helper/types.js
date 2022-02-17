module.exports = {
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
    BeefyPayload: 'Vec<([u8; 2], Vec<u8>)>',
    EcdsaSignature: {
      b: 'BitVec',
      i: 'u32',
      s: '[u8; 65]'
    }
  }
}
