import {BigNumber, utils} from 'ethers';
const {defaultAbiCoder, keccak256, hexZeroPad} = utils;

export type MultiClaim = {
  to: string;
  erc1155: Array<ERC1155Claim>;
  erc721: Array<ERC721Claim>;
  erc20: {
    amounts: Array<number>;
    contractAddresses: Array<string>;
  };
  salt?: string;
};

export type MultiClaimProof = MultiClaim & {proof: Array<string>};

export type MultiClaimCalldata = {
  root: string;
  claim: MultiClaim;
  proof: Array<string>;
}

export type ERC1155Claim = {
  ids: Array<string>;
  values: Array<number>;
  contractAddress: string;
};

export type ERC721Claim = {
  ids: Array<number>;
  contractAddress: string;
};

// Multi Claim

function calculateMultiClaimHash(claim: MultiClaim): string {
  const types = [];
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const values: any = [];
  types.push(
    'tuple(address to, tuple(uint256[] ids, uint256[] values, address contractAddress)[] erc1155, tuple(uint256[] ids, address contractAddress)[] erc721, tuple(uint256[] amounts, address[] contractAddresses) erc20, bytes32 salt)'
  );
  values.push(claim);
  return keccak256(defaultAbiCoder.encode(types, values));
}

function saltMultiClaim(
  claims: MultiClaim[],
  salt: string
): Array<MultiClaim> {
  return claims.map((claim) => {
    const bn = BigNumber.from(salt)
    const newClaim: MultiClaim = {
      ...claim,
      salt: hexZeroPad(bn.toHexString(), 32)
    };
    return newClaim;
  });
}

function createDataArrayMultiClaim(
  claims: MultiClaim[]
): string[] {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const data: string[] = [];

  claims.forEach((claim: MultiClaim) => {
    data.push(calculateMultiClaimHash(claim));
  });

  return data;
}

const helpers = {
  calculateMultiClaimHash,
  createDataArrayMultiClaim,
  saltMultiClaim,
};

export default helpers;
