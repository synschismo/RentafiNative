// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import '../RentaFiNative/ERC721RentaFi.sol';

contract MockERC721RentaFi is RentafiNative {
  constructor() RentafiNative('mock', 'MOCK') {}

  function mint(address to, uint256 tokenId) external {
    _mint(to, tokenId);
  }

  function burn(uint256 tokenId) external {
    _burn(tokenId);
  }

  function transfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) external {
    _transfer(_from, _to, _tokenId);
  }

  //以下coverage用
  function checkSupportsInterface(bytes4 interfaceId) public view returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function checkBaseURI() public view returns (string memory) {
    return _baseURI();
  }

  function checkTokenURI(uint256 tokenId) public view returns (string memory) {
    return tokenURI(tokenId);
  }
}
