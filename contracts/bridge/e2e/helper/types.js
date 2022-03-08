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
      signatures: {
        hack: '[u8; 6]',
        sigs: 'Vec<EcdsaSignature>'
      }
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
      nextValidatorSet: 'BeefyNextAuthoritySet'
    },
    EcdsaSignature: '[u8; 65]',
    ConsensusLog: {
      _enum: {
        0: null,
        AuthoritiesChange: {
          validators: 'Vec<AuthorityId>',
          id: 'ValidatorSetId'
        }
      }
    },
    AuthorityId: '[u8; 33]'
  }
}
