// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import './RentafiNative.sol';

contract MockRentafiNative is RentafiNative {
  constructor() RentafiNative('mockRN', 'MOCKRN') {}

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
}
