// // SPDX-License-Identifier: MIT

// pragma solidity >=0.5.0 <0.6.0;

// import "./Blake2b.sol";
// import "./common/Ownable.sol";
// import "./common/Timelock.sol";
// import "./common/Pausable.sol";
// import "./common/ECDSA.sol";
// import "./common/Hash.sol";
// import "./common/SafeMath.sol";
// import "./common/Input.sol";

// import "./MMR.sol";
// import "./SimpleMerkleProof.sol";

// pragma experimental ABIEncoderV2;

// contract Backing is Ownable, Pausable {
//     event MintRingEvent(address recipient, uint256 value, bytes32 accountId);
//     event MintKtonEvent(address recipient, uint256 value, bytes32 accountId);


//     bytes lockTokenKey;

//     constructor(
//       bytes memory 
//     ) public {

//     }

//     function verifyLockTokenProof(
//         bytes32 root,
//         uint32 index,
//         uint256 position,
//         bytes memory blockHeader,
//         bytes32[] memory peaks,
//         bytes32[] memory siblings,
//         bytes memory proofstr,
//         bytes memory key
//     ) public view returns (bytes memory){
//         // verify block proof
//         require(
//             verifyBlockProof(root, index, position, blockHeader, peaks, siblings),
//             "Relay: Block header proof varification failed"
//         );

//         // get state root
//         bytes32 stateRoot = Scale.decodeStateRootFromBlockHeader(blockHeader);

//         return getLockTokenReceipt(stateRoot, proofstr, key);
//     }

// }
