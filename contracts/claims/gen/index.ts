/**
 * How to use:
 *  - yarn gen <NETWORK> <CLAIM_NAME> <SALT>
 */
import fs from 'fs-extra';

import {createClaimMerkleTree} from './helper/getClaims';
import helpers, {MultiClaim} from './helper/merkleTreeHelper';
const {calculateMultiClaimHash} = helpers;

const args      = process.argv.slice(2);
const network   = args[0];
const claimFile = args[1];
const salt      = args[2];

const func = async function () {
  let claimData: MultiClaim[];
  try {
    claimData = fs.readJSONSync(
      `../data/${network}/data/${claimFile}_${salt}.json`
    );
  } catch (e) {
    console.log('Error', e);
    return;
  }

  const {merkleRootHash, saltedClaims, tree} = createClaimMerkleTree(
    claimData,
    salt
  );

  const contractAddresses: string[] = [];
  const addAddress = (address: string) => {
    address = address.toLowerCase();
    if (!contractAddresses.includes(address)) contractAddresses.push(address);
  };
  claimData.forEach((claim) => {
    claim.erc1155.forEach((erc1155) => addAddress(erc1155.contractAddress));
    claim.erc721.forEach((erc721) => addAddress(erc721.contractAddress));
    claim.erc20.contractAddresses.forEach((erc20) => addAddress(erc20));
  });

  const claimsWithProofs: (MultiClaim & {proof: string[]})[] = [];
  let tos: any = {};
  for (const claim of saltedClaims) {
    if (!tos[claim.to]) {
      claimsWithProofs.push({
        ...claim,
        proof: tree.getProof(calculateMultiClaimHash(claim)),
      });
      tos[claim.to] = true;
    } else {
      throw new Error(`Repeated To: ${claim.to}`);
    }
  }
  const basePath = `../data/${network}`;
  const proofPath = `${basePath}/proof/${claimFile}_${salt}.json`;
  const rootHashPath = `${basePath}/root/${claimFile}_${salt}.json`;
  fs.outputJSONSync(proofPath, claimsWithProofs);
  fs.outputFileSync(rootHashPath, merkleRootHash);
  console.log(`Proofs at: ${proofPath}`);
  console.log(`Hash at: ${rootHashPath}`);
};
export default func;

if (require.main === module) {
  func();
}
