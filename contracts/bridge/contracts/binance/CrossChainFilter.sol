// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

contract CrossCchainFilter {
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Allow(bytes4 indexed usr);
    event Forbid(bytes4 indexed usr);
    event SetRoot(address indexed newRoot);

    address public root;
    mapping (address => uint) public wards;
    mapping (bytes4 => uint)  public sigs;

    modifier sudo { require(msg.sender == root); _; }
    function setRoot(address usr) public sudo { root = usr; emit SetRoot(usr); }
    function rely(address usr)    public sudo { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr)    public sudo { wards[usr] = 0; emit Deny(usr); }
    function allow(bytes4 sig)    public sudo { sigs[sig] = 1; emit Allow(sig); }
    function forbid(bytes4 sig)   public sudo { sigs[sig] = 0; emit Forbid(sig); }

    constructor(address[] memory _wards, bytes4[] memory _sigs) public {
        root = msg.sender;
        emit SetRoot(root);
        for (uint i = 0; i < _wards.length; i++) { rely(_wards[i]); }
        for (uint j = 0; j < _sigs.length; j++) { allow(_sigs[j]); }
    }

    function filter(
        address _src, address, bytes4 _sig
    ) public view returns (bool) {
        return wards[_src] == 1 && sigs[_sig] == 1;
    }
}
