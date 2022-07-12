// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./RelayAuthorities.sol";
import "../../spec/POSACommitmentScheme.sol";

contract POSALightClient is POSACommitmentScheme, RelayAuthorities {

    event MessageRootImported(uint256 blockNumber, bytes32 messageRoot);

    uint256 public latestBlockNumber;
    bytes32 public latestChainMessagesRoot;

    constructor(
        bytes32 _network,
        address[] memory _relayers,
        uint256 _threshold
    ) RelayAuthorities(_network, _relayers, _threshold) {}

    function import_message_commitment(
        Commitment calldata commitment,
        bytes[] calldata signatures
    ) external payable {
        // Encode and hash the commitment
        bytes32 commitmentHash = hash(commitment);
        checkRelayerSignatures(commitmentHash, signatures);

        require(commitment.blockNumber > latestBlockNumber, "!new");
        latestBlockNumber = commitment.blockNumber;
        latestChainMessagesRoot = commitment.messageRoot;
        emit MessageRootImported(commitment.blockNumber, commitment.messageRoot);
    }
}
