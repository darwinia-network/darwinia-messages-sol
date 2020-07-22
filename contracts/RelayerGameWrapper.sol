pragma solidity >=0.5.0 <0.6.0;
pragma experimental ABIEncoderV2;

import "./RelayerGame.sol";

contract RelayerGameWrapper {
    using RelayerGame for RelayerGame.Game;

    RelayerGame.Game public game;

    constructor() public {}

    function startGame(
        /// 100
        uint256 sample,
        /// 0x0
        bytes32 parentProposalHash,
        /// [H100a]
        bytes32[] memory proposalHash,
        /// [100a]
        bytes[] memory proposalValue
    ) public {
        game.startGame(sample, parentProposalHash, proposalHash, proposalValue);
    }

    function setDeadLineStep(uint256 step) public {
        game.setDeadLineStep(step);
    }

    function updateRound(
        uint256 roundIndex,
        bytes32 parentProposalHash,
        bytes32[] memory proposalHash,
        bytes[] memory proposalValue
    ) public {
        game.updateRound(roundIndex, parentProposalHash, proposalHash, proposalValue);
    }

    function appendProposalByRound(
        /// 0
        uint256 roundIndex,
        /// 50
        // uint samples,
        /// H100a
        /// H50b
        bytes32 parentProposalHash,
        /// [H50b]
        /// [H75e, H25j]
        bytes32[] memory proposalHash,
        /// [50b]
        bytes[] memory proposalValue
    ) public {
        game.appendProposalByRound(roundIndex, parentProposalHash, proposalHash, proposalValue);
    }

    function getRoundInfo(uint256 index)
        public
        view
        returns (
            uint256 deadline,
            uint256 activeProposalStart,
            uint256 activeProposalEnd,
            bytes32[] memory proposalLeafs,
            uint256[] memory samples,
            bool close
        )
    {
        return (
            game.rounds[index].deadline,
            game.rounds[index].activeProposalStart,
            game.rounds[index].activeProposalEnd,
            game.rounds[index].proposalLeafs,
            game.rounds[index].samples,
            game.rounds[index].close
        );
    }


    function getGameInfo()
        public
        view
        returns (
            bytes32 mmrRoot,
            uint32[] memory samples,
            uint256 deadLineStep,
            uint256 latestRoundIndex
        )
    {
        return (
            game.mmrRoot,
            game.samples,
            game.deadLineStep,
            game.latestRoundIndex
        );
    }
}
