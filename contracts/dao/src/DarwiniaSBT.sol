// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts@4.8.2/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.8.2/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts@4.8.2/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.8.2/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.8.2/access/Ownable.sol";
import "@openzeppelin/contracts@4.8.2/utils/Counters.sol";
import "./IERC5192.sol";

/// @dev Implementation of https://eips.ethereum.org/EIPS/eip-5192[ERC5192]
/// @custom:security-contact security@darwinia.network
/// Spec:
/// 1. 
contract DarwiniaSBT is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable, IERC5192 {
    using Counters for Counters.Counter;

    error ErrLocked();

    string private _name;
    string private _symbol;
    Counters.Counter private _tokenIdCounter;

    bool private constant LOCKED = true;

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external onlyOwner { wards[guy] = 1; }
    function deny(address guy) external onlyOwner { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "DDP/not-authorized");
        _;
    }

    constructor() ERC721("Darwinia DAO Profile", "DDP") {
        wards[_msgSender()] = 1;
    }

    function safeMint(address to, string memory uri) public auth {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        emit Locked(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        _setTokenURI(tokenId, uri);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function setName(string calldata newName) external onlyOwner {
        _name = newName;
    }

    function setSymbol(string calldata newSymbol) external onlyOwner {
        _symbol = newSymbol;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // Only contract owner could transfer/burn SBT
    function _isApprovedOrOwner(address spender, uint256) internal view override returns (bool) {
        if(spender != owner()) revert ErrLocked;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function locked(uint256 tokenId) external view returns (bool) {
        _requireMinted(tokenId);
        return LOCKED;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return interfaceId == type(IERC5192).interfaceId || super.supportsInterface(interfaceId);
    }
}
