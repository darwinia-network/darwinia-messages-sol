// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./RelayAuthorities.sol";
import "../common/MessageVerifier.sol";
import "../../spec/POSACommitmentScheme.sol";

contract POSALightClient is POSACommitmentScheme, MessageVerifier, RelayAuthorities {

    event MessageRootImported(uint256 blockNumber, bytes32 messageRoot);

    // keccak256(
    //     "SignCommitment(bytes32 network,bytes32 commitment,uint256 nonce)"
    // );
    bytes32 internal constant COMMIT_TYPEHASH = 0x0324ca0ca4d529e0eefcc6d123bd17ec982498cf2e732160cc47d2504825e4b2;

    uint256 public latestBlockNumber;
    bytes32 public latestChainMessagesRoot;

    constructor(
        bytes32 _network,
        address[] memory _relayers,
        uint256 _threshold
    ) RelayAuthorities(_network, _relayers, _threshold) {}

    function message_root() public view override returns (bytes32) {
        return latestChainMessagesRoot;
    }

    function import_message_commitment(
        Commitment calldata commitment,
        bytes[] calldata signatures
    ) external payable {
        // Encode and hash the commitment
        bytes32 commitmentHash = hash(commitment);
        verifyCommitment(commitmentHash, signatures);

        require(commitment.blockNumber > latestBlockNumber, "!new");
        latestBlockNumber = commitment.blockNumber;
        latestChainMessagesRoot = commitment.messageRoot;
        emit MessageRootImported(commitment.blockNumber, commitment.messageRoot);
    }

    function verifyCommitment(bytes32 commitmentHash, bytes[] memory signatures) internal view {
        bytes32 structHash =
            keccak256(
                abi.encode(
                    COMMIT_TYPEHASH,
                    NETWORK,
                    commitmentHash,
                    nonce
                )
            );
        checkRelayerSignatures(structHash, signatures);
    }
}
