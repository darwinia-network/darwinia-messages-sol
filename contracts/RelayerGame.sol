pragma solidity >=0.5.0 <0.6.0;

library RelayerGame {
    struct Game {
        bytes32 mmrRoot;
        Block finalizedBlock;
        uint32[] samples;
        uint deadLineStep = 600;
        mapping(uint32 => Proposal) proposalPool;
        Round rounds;
    }

    struct Round {
        uint deadline;
        bytes32[][] proposal; // [[H100a,[1,2,3],[[],[],[]]],[H100b]]?
        uint samples; // [100, 50]
    }

    struct Block {
        bytes32 hash;
        bytes data;
    }

    struct Proposal {
        uint256 id;
        address sponsor;
        mapping(uint32 => Block) block;
    }

    // Todo
    function checkSamples(Game storage game, uint[] memory samples) public view returns (bool){
        return true;
    }

    function appendSamples(Game storage game, uint[] memory samples) private {
        for (uint i = 0; i < samples.length; i++) {
            game.rounds.samples.push(samples[i]);
        }
    }

    function appendProposal(
        Game storage game,
        uint index,
        bytes32[] memory proposalHash,
        bytes memory proposalValue) private {
        if(game.rounds.samples.length == 1) {
            game.rounds.proposal.push(proposalHash);
        } else {
            for (uint i = 0; i < proposalHash.length; i++) {    
                game.rounds.proposal[index].push(proposalHash[i])
            }
        }
    }

    function updateDeadline(Game storage game) private {
        game.rounds.deadline = game.rounds.deadline + game.deadLineStep;
    }

    functino checkProposalValue() {

    }

    /// 1- [100],[H100a],[100a]
    /// 1- [100],[H100b],[100b]
    /// 2- [50],[H50a],[50a]
    /// 3- [25, 75],[H25a, H75a],[25a, 75a]
    function setProposal(
        Game storage game, 
    uint[] memory samples, 
    uint preProposalIndex, 
    bytes32[] memory proposalHash, 
    bytes memory proposalValue) internal {
        // check the submisstion follows the samples
        require(checkSamples(samples), "Invalid Samples of the round.");
        require(checkProposalHash(proposalHash), "Invalid Proposal Hash of the round.");
        appendSamples(samples);
        appendProposal(preProposalIndex, proposalHash);
    }

    function claimToken() public auth {

    }


}

