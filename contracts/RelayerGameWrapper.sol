pragma solidity >=0.5.0 <0.6.0;

import "./RelayerGame.sol";

contract RelayerGameWrapper {
    using RelayerGame for RelayerGame.Game;

    RelayerGame.Game game;
    constructor() public {

    }
}