import fs from 'fs';
import {BigNumber} from 'ethers';
import MerkleTree from './merkleTree';
import helpers, {MultiClaim} from './merkleTreeHelper';

const {
  createDataArrayMultiClaim,
  saltMultiClaim,
} = helpers;

export function createClaimMerkleTree(
  claimData: Array<MultiClaim>,
  salt: string
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
): any {

  const saltedClaims = saltMultiClaim(claimData, salt);
  const tree = new MerkleTree(
    createDataArrayMultiClaim(saltedClaims)
  );
  const merkleRootHash = tree.getRoot().hash;

  return {
    merkleRootHash,
    saltedClaims,
    tree,
  };
}
