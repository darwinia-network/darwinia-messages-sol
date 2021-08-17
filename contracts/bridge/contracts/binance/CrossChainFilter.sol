// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

contract CrossChainFilter {
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event SetRoot(address indexed newRoot);

    address public root;
    mapping (address => uint) public wards;

    modifier filter(address origin) {
        require(filtered(origin), "Filter: not-filtered");
        _;
    }
    modifier sudo { require(msg.sender == root); _; }
    function setRoot(address usr) public sudo { root = usr; emit SetRoot(usr); }
    function rely(address usr)    public sudo { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr)    public sudo { wards[usr] = 0; emit Deny(usr); }

    constructor() public {
        root = msg.sender;
        emit SetRoot(root);
    }

    function filtered(address _src) public view returns (bool) {
        return wards[_src] == 1;
    }
}
