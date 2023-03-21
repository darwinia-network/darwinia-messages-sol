// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts@4.8.2/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.8.2/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts@4.8.2/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.8.2/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.8.2/access/Ownable.sol";
import "@openzeppelin/contracts@4.8.2/utils/Counters.sol";
import "./IERC5192.sol";

/// @dev Implementation of https://eips.ethereum.org/EIPS/eip-5192[ERC5192] Minimal Soulbound NFTs
/// and https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard including the Metadata extension
/// Specification:
/// 1. SBT tokens are non-transferable.
/// 2. Assume at extreme condition (lost private key), community multisig (contract owner) can transfer the token to the new wallet.
/// 3. SBT Tokens are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
/// 4. The maximum token id cannot exceed 2**256 - 1 (max value of uint256).
/// 5. Metadata and image are pinned to ipfs.
/// 6. Token uri metadata are changeable by contract owner.
/// @custom:security-contact security@darwinia.network
contract DarwiniaDaoSBT is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable, IERC5192 {
    using Counters for Counters.Counter;

    error ErrLocked();

    Counters.Counter private _tokenIdCounter;
    string private _base;

    bool private constant LOCKED = true;

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external onlyOwner { wards[guy] = 1; }
    function deny(address guy) external onlyOwner { wards[guy] = 0; }
    modifier auth {
        require(wards[_msgSender()] == 1, "DDP/not-authorized");
        _;
    }

    constructor(address dao) ERC721("Darwinia DAO Profile", "DDP") {
        wards[dao] = 1;
        _transferOwnership(dao);
    }

    function setBaseURI(string calldata newBase) external auth {
        _base = newBase;
    }

    // uid: bytes32
    // ipfs://dir_cid/{uri=uid}
    function safeMint(address to, string memory uri) public auth {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        emit Locked(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // Only contract owner could transfer/burn SBT
    function _isApprovedOrOwner(address spender, uint256) internal view override returns (bool) {
        if(spender != owner()) revert ErrLocked();
        return true;
    }

    function approve(address to, uint256 tokenId) public override(IERC721, ERC721) {
        revert ErrLocked();
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(IERC721, ERC721) {
        revert ErrLocked();
        super.setApprovalForAll(operator, approved);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _base;
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
