/**
 * How to use:
 *  - yarn verify <NETWORK> <CLAIM_NAME> <SALT>
 */
import fs from 'fs-extra';
import {MultiClaim, MultiClaimProof, MultiClaimCalldata} from './helper/merkleTreeHelper';
import {utils} from 'ethers';
const {defaultAbiCoder} = utils;

const args      = process.argv.slice(2);
const network   = args[0];
const claimFile = args[1];
const salt      = args[2];

const func = async function () {
  let proofs: MultiClaimProof[];
  let root: string;
  try {
    proofs = fs.readJSONSync(
      `../data/${network}/proof/${claimFile}_${salt}.json`
    );
  } catch (e) {
    console.log('Error', e);
    return;
  }

  try {
    root = await fs.readFile(
      `../data/${network}/root/${claimFile}_${salt}.json`,
      'utf8'
    );
  } catch (e) {
    console.log('Error', e);
    return;
  }

  const types = [];
  types.push('bytes32');
  types.push(
    'tuple(address to, tuple(uint256[] ids, uint256[] values, address contractAddress)[] erc1155, tuple(uint256[] ids, address contractAddress)[] erc721, tuple(uint256[] amounts, address[] contractAddresses) erc20, bytes32 salt)'
  );
  types.push('bytes32[] proof');
  // 0x25839ca7
  // claimMultipleTokens(bytes32,(address,(uint256[],uint256[],address)[],(uint256[],address)[],(uint256[],address[]),bytes32),bytes32[])
  const verify: any = {};
  for (const proof of proofs) {
    if (verify[proof.to]) {
      throw new Error(`Repeated To: ${proof.to}`);
    }
    const values: any = [];
    const claim: MultiClaim = {
      to: proof.to,
      erc1155: proof.erc1155,
      erc721: proof.erc721,
      erc20: proof.erc20,
      salt: proof.salt
    }
    const value: MultiClaimCalldata = {
      root: root,
      claim: claim,
      proof: proof.proof
    }
    values.push(value.root);
    values.push(value.claim);
    values.push(value.proof);
    let calldata = defaultAbiCoder.encode(types, values);
    calldata = utils.hexConcat(["0x25839ca7", calldata])
    verify[proof.to] = calldata;
  }

  const basePath = `../data/${network}`;
  const verifyPath = `${basePath}/verify/${claimFile}_${salt}.json`;
  fs.outputJSONSync(verifyPath, verify);
  console.log(`Verify at: ${verifyPath}`);
};
export default func;

if (require.main === module) {
  func();
}
