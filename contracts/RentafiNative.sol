// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract RentafiNative is ERC721 {
  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // MODIFIED - RentaFi Native
  // Array with all token ids, used for enumeration
  uint256[] private _allTokens;

  // MODIFIED - RentaFi Native
  struct OwnerInfo {
    address owner; // address of user role
    address superOwner;
    uint256 expires; // unix timestamp, user expires
  }

  // Mapping from token ID to OwnerInfo
  mapping(uint256 => OwnerInfo) private _owners; // renter's info

  // MODIFIED - RentaFi Native
  mapping(uint256 => address) private _superOwners; // as a ERC721.owners

  // Mapping owner address to token count
  mapping(address => uint256) private _balances; // renter's balance

  // MODIFIED - RentaFi Native
  mapping(address => uint256) private _superBalances; // as a ERC721.balances

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

  // MODIFIED - RentaFi Native
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      // TODO
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  // MODIFIED - RentaFi Native
  function balanceOf(address owner) public view virtual override returns (uint256) {
    require(owner != address(0), 'ERC721: address zero is not a valid owner');
    uint256 _rental;
    uint256 _lend;
    for (uint256 i = 0; i < _allTokens.length; ) {
      if (_owners[_allTokens[i]].expires >= block.timestamp) {
        if (_owners[_allTokens[i]].owner == owner) _rental++;
        if (_owners[_allTokens[i]].superOwner == owner) _lend++;
      }
      unchecked {
        i++;
      }
    }
    return superBalanceOf(owner) + _rental - _lend;
  }

  // MODIFIED - RentaFi Native
  function superBalanceOf(address superOwner) public view virtual returns (uint256) {
    require(superOwner != address(0), 'ERC721: address zero is not a valid owner');
    return _superBalances[superOwner];
  }

  // MODIFIED - RentaFi Native
  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    if (uint256(_owners[tokenId].expires) >= block.timestamp) {
      return _owners[tokenId].owner;
    } else {
      return superOwnerOf(tokenId);
    }
  }

  // MODIFIED - RentaFi Native
  function setOwner(
    uint256 tokenId,
    address owner,
    uint64 expires
  ) public virtual {
    require(
      _isApprovedOrSuperOwner(msg.sender, tokenId),
      'ERC721: caller is not token superOwner nor approved'
    );
    OwnerInfo storage info = _owners[tokenId];
    info.owner = owner;
    info.expires = expires;
    info.superOwner = msg.sender;
    emit UpdateOwner(tokenId, owner, msg.sender, expires);
  }

  // MODIFIED - RentaFi Native
  event UpdateOwner(
    uint256 indexed tokenId,
    address indexed owner,
    address indexed lender,
    uint64 expires
  );

  // MODIFIED - RentaFi Native
  function ownerExpires(uint256 tokenId) public view returns (uint256) {
    return _owners[tokenId].expires;
  }

  // MODIFIED - RentaFi Native
  function superOwnerOf(uint256 tokenId) public view virtual returns (address) {
    address superOwner = _superOwners[tokenId];
    require(superOwner != address(0), 'ERC721: invalid token ID');
    return superOwner;
  }

  // MODIFIED - RentaFi Native
  function approve(address to, uint256 tokenId) public virtual override {
    address superOwner = superOwnerOf(tokenId);
    require(to != superOwner, 'ERC721: approval to current superOwner');

    require(
      _msgSender() == superOwner || isApprovedForAll(superOwner, _msgSender()),
      'ERC721: approve caller is not token superOwner nor approved for all'
    );

    _approve(to, tokenId);
  }

  // MODIFIED - RentaFi Native
  function isApprovedForAll(address superOwner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[superOwner][operator];
  }

  // MODIFIED - RentaFi Native
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrSuperOwner(_msgSender(), tokenId),
      'ERC721: caller is not token superOwner nor approved'
    );

    _transfer(from, to, tokenId);
  }

  // MODIFIED - RentaFi Native
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual override {
    require(
      _isApprovedOrSuperOwner(_msgSender(), tokenId),
      'ERC721: caller is not token superOwner nor approved'
    );
    _safeTransfer(from, to, tokenId, data);
  }

  // MODIFIED - RentaFi Native
  function _exists(uint256 tokenId) internal view virtual override returns (bool) {
    return _superOwners[tokenId] != address(0);
  }

  // MODIFIED - RentaFi Native
  function _isApprovedOrSuperOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    address superOwner = superOwnerOf(tokenId);
    return (spender == superOwner ||
      isApprovedForAll(superOwner, spender) ||
      getApproved(tokenId) == spender);
  }

  // MODIFIED - RentaFi Native
  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    override
    returns (bool)
  {
    return _isApprovedOrSuperOwner(spender, tokenId);
  }

  // MODIFIED - RentaFi Native
  function _mint(address to, uint256 tokenId) internal virtual override {
    require(to != address(0), 'ERC721: mint to the zero address');
    require(!_exists(tokenId), 'ERC721: token already minted');

    _beforeTokenTransfer(address(0), to, tokenId);

    _superBalances[to] += 1;
    _superOwners[tokenId] = to;
    _allTokens.push(tokenId);

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId);
  }

  // MODIFIED - RentaFi Native
  function _burn(uint256 tokenId) internal virtual override {
    address superOwner = superOwnerOf(tokenId);

    _beforeTokenTransfer(superOwner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);

    _superBalances[superOwner] -= 1;
    delete _superOwners[tokenId];

    for (uint256 i = 0; i < _allTokens.length; i++) {
      if (_allTokens[i] == tokenId) {
        if (i != _allTokens.length - 1) {
          _allTokens[i] = _allTokens[_allTokens.length - 1];
        }
        _allTokens.pop();
        break;
      }
    }

    emit Transfer(superOwner, address(0), tokenId);

    _afterTokenTransfer(superOwner, address(0), tokenId);
  }

  // MODIFIED - RentaFi Native
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    require(superOwnerOf(tokenId) == from, 'ERC721: transfer from incorrect superOwner');
    require(to != address(0), 'ERC721: transfer to the zero address');

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _superBalances[from] -= 1;
    _superBalances[to] += 1;
    _superOwners[tokenId] = to;

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId);
  }

  // MODIFIED - RentaFi Native
  function _approve(address to, uint256 tokenId) internal virtual override {
    _tokenApprovals[tokenId] = to;
    emit Approval(superOwnerOf(tokenId), to, tokenId);
  }

  // MODIFIED - RentaFi Native
  function _setApprovalForAll(
    address superOwner,
    address operator,
    bool approved
  ) internal virtual override {
    require(superOwner != operator, 'ERC721: approve to caller');
    _operatorApprovals[superOwner][operator] = approved;
    emit ApprovalForAll(superOwner, operator, approved);
  }
}
