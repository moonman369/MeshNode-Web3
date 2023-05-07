// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Stack3RareMintNFT is ERC721URIStorage, Ownable {

    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private s_tokenIds;

    uint256 immutable public s_maxSupply;
    string public s_baseUri;

    constructor (uint256 _maxSupply, string memory _baseUri) ERC721 ("Stack3RareMintNFT", "STK3") {
        s_maxSupply = _maxSupply;
        s_baseUri = _baseUri;
    }

    function devMint (address _to) external onlyOwner {
        uint256 newId = s_tokenIds.current();
        require (newId <= s_maxSupply, "STK3: Max supply minted.");
        s_tokenIds.increment();
        _safeMint (_to, newId);
        _setTokenURI (newId, string(abi.encodePacked(s_baseUri, newId.toString(), ".json")));
    }



}
