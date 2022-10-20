// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract MockERC721 is ERC721 {
  using Counters for Counters.Counter;
  Counters.Counter private totalCreated;

  constructor() ERC721('Mock721', 'M721') {}

  function tokenURI(uint256 tokenId) public pure override returns (string memory) {
    return Strings.toString(tokenId);
  }

  function mint() external {
    totalCreated.increment();
    _mint(msg.sender, totalCreated.current());
  }

  function transfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) external {
    _transfer(_from, _to, _tokenId);
  }

  function burn(uint256 _tokenId) external {
    _burn(_tokenId);
  }
}
