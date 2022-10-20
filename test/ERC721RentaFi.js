const { describe, it, before } = require('mocha');
const { expect } = require('chai');
const { ethers, network } = require('hardhat');
const BN = ethers.BigNumber.from;

describe('単体テスト - ERC721RentaFi', async () => {
  let collectionOwnerEOA, lenderEOA, renterEOA, thirdEOA;
  let collection;
  before('デプロイ', async () => {
    // 署名者の取得
    [collectionOwnerEOA, lenderEOA, renterEOA, thirdEOA] = await ethers.getSigners();
    // コントラクトのデプロイ
    const MockERC721RentaFi = await ethers.getContractFactory('MockERC721RentaFi', collectionOwnerEOA);
    collection = await MockERC721RentaFi.deploy();
  });

  describe('トークンのミントと貸出', () => {
    it('トークンを3つミント', async () => {
      const mintFullfilled_1 = await collection.connect(lenderEOA).mint(lenderEOA.address, BN(1));
      await mintFullfilled_1.wait();
      const mintFullfilled_2 = await collection.connect(lenderEOA).mint(lenderEOA.address, BN(2));
      await mintFullfilled_2.wait();
      const mintFullfilled_3 = await collection.connect(lenderEOA).mint(lenderEOA.address, BN(3));
      await mintFullfilled_3.wait();
      expect(await collection._allTokens(0)).to.equal(BN(1));
      expect(await collection._allTokens(1)).to.equal(BN(2));
      expect(await collection._allTokens(2)).to.equal(BN(3));
    });

    it('superOwnerと保有数を確認', async () => {
      expect(await collection.superOwnerOf(BN(1))).to.equal(lenderEOA.address);
      expect(await collection.superOwnerOf(BN(2))).to.equal(lenderEOA.address);
      expect(await collection.superOwnerOf(BN(3))).to.equal(lenderEOA.address);
      expect(await collection.superOwnerBalanceOf(lenderEOA.address)).to.equal(BN(3));
    });

    it('tokenID: 3をrenterEOAに送付', async () => {
      const transfered = collection.connect(lenderEOA)['safeTransferFrom(address,address,uint256)'](lenderEOA.address, renterEOA.address, BN(3));
      await (await transfered).wait();
      expect(await collection.superOwnerOf(BN(3))).to.equal(renterEOA.address);
    });

    it('renterEOAの保有を確認', async () => {
      expect(await collection.superOwnerOf(BN(3))).to.equal(renterEOA.address);
      expect(await collection.superOwnerBalanceOf(renterEOA.address)).to.equal(BN(1));
    });

    it('approveForAllの確認', async () => {
      // false
      const error = collection.connect(lenderEOA).setApprovalForAll(lenderEOA.address, true);
      await expect(error).to.be.revertedWith('ERC721: approve to caller');
      // true
      await collection.connect(lenderEOA).setApprovalForAll(thirdEOA.address, true);
      expect(await collection.isApprovedForAll(lenderEOA.address, thirdEOA.address)).to.equal(true);
    });

    it('approveの確認とエラー回収', async () => {
      //自分自身にapproveはできない
      let approved = collection.connect(renterEOA).approve(renterEOA.address, BN(3));
      await expect(approved).to.be.revertedWith('ERC721: approval to current superOwner');
      //他人のNFTをapproveできない
      approved = collection.connect(renterEOA).approve(thirdEOA.address, BN(1));
      await expect(approved).to.be.revertedWith('ERC721: approve caller is not token superOwner nor approved for all');
      //自分のNFTを第三者にapproveは可能
      await collection.connect(renterEOA).approve(thirdEOA.address, BN(3));
    });

    it('コントラクトに送付', async () => {
      const transfered = collection.connect(renterEOA)['safeTransferFrom(address,address,uint256)'](renterEOA.address, collection.address, BN(3));
      await expect(transfered).to.be.revertedWith('ERC721: transfer to non ERC721Receiver implementer');
    });

    it('lenderEOAの保有を確認', async () => {
      expect(await collection.superOwnerOf(BN(1))).to.equal(lenderEOA.address);
      expect(await collection.superOwnerOf(BN(2))).to.equal(lenderEOA.address);
      expect(await collection.superOwnerBalanceOf(lenderEOA.address)).to.equal(BN(2));
    });

    // renterEOA has tokenID:3 and borrow tokenID:1, so he has 2 tokens durning rental time.
    let rentalExpireTime;
    it('superOwnerからrenterEOAへ貸出', async () => {
      network.provider.send('evm_mine');
      const blockNumber = await ethers.provider.getBlockNumber();
      const { timestamp } = await ethers.provider.getBlock(blockNumber);
      rentalExpireTime = timestamp + 300; // 5min
      const setOwnerFullfilled = await collection.connect(lenderEOA).setOwner(BN(1), renterEOA.address, rentalExpireTime);
      await setOwnerFullfilled.wait();
      expect(await collection.balanceOf(renterEOA.address)).to.equal(BN(2)); //既に持っているNFT#3と借りたNFT#1を1つ
      expect(await collection.ownerOf(BN(1))).to.equal(renterEOA.address);
      //貸した側のbalanceOfとsuperOwnerBalanceOfの確認
      expect(await collection.superOwnerBalanceOf(lenderEOA.address)).to.equal(BN(2));
      expect(await collection.balanceOf(lenderEOA.address)).to.equal(BN(1)); //本来は2つ持っていたが、1つ貸し出したので1
    });

    it('非保有者のbalanceOfの確認', async () => {
      expect(await collection.balanceOf(thirdEOA.address)).to.equal(BN(0));
    });

    it('renterEOAが許可しないメソッドを実行', async () => {
      approve = collection.connect(renterEOA).approve(thirdEOA.address, BN(1));
      await expect(approve).to.be.revertedWith('ERC721: approve caller is not token superOwner nor approved for all');

      safeTransferFrom = collection.connect(renterEOA)['safeTransferFrom(address,address,uint256)'](renterEOA.address, thirdEOA.address, BN(1));
      await expect(safeTransferFrom).to.be.revertedWith('ERC721: caller is not token superOwner nor approved');

      setOwner = collection.connect(renterEOA).setOwner(BN(1), thirdEOA.address, rentalExpireTime);
      await expect(setOwner).to.be.revertedWith('ERC721: caller is not token superOwner nor approved');

      transferFrom = collection.connect(renterEOA).transferFrom(renterEOA.address, thirdEOA.address, BN(1));
      await expect(transferFrom).to.be.revertedWith('ERC721: caller is not token superOwner nor approved');
    });

    it('レンタル終了後のrenterEOAの保有数とownerOf()の確認', async () => {
      network.provider.send('evm_increaseTime', [300]);
      network.provider.send('evm_mine');
      expect(await collection.balanceOf(renterEOA.address)).to.equal(BN(1)); //元々持っていたNFT1つだけになる
      expect(await collection.ownerOf(BN(1))).to.equal(lenderEOA.address); //貸しての元に戻っている
      //貸した側のbalanceOfとsuperOwnerBalanceOfの確認
      expect(await collection.superOwnerBalanceOf(lenderEOA.address)).to.equal(BN(2)); //transferしていなければ返却前後で変わらない
      expect(await collection.balanceOf(lenderEOA.address)).to.equal(BN(2)); //本来は2つ持っている状態で、1つ貸し、戻ってきたので2
    });
  });

  describe('トークンのミントと貸出', () => {
    it('burnとallTokens配列の確認', async () => {
      //tokenID: 1, 2, 3
      //tokenID 2 をBurn => 1, 3
      let burned = await collection.burn(BN(2));
      await (await burned).wait();
      expect(await collection._allTokens(0)).to.equal(BN(1));
      expect(await collection._allTokens(1)).to.equal(BN(3));
      //tokenID 3 をBurn => 1
      burned = await collection.burn(BN(3));
      await (await burned).wait();
      expect(await collection._allTokens(0)).to.equal(BN(1));
    });

    it('nameとsymbolの確認', async () => {
      expect(await collection.name()).to.equal('mock');
      expect(await collection.symbol()).to.equal('MOCK');
    });

    it('checkSupportsInterfaceの確認', async () => {
      expect(await collection.checkSupportsInterface('0x5b5e139f')).to.equal(true);
    });

    it('BaseURIとTokenURIの確認', async () => {
      expect(await collection.checkBaseURI()).to.equal('');
      expect(await collection.checkTokenURI(BN(1))).to.equal('');
      await expect(collection.checkTokenURI(BN(99))).to.be.revertedWith('ERC721: invalid token ID');
    });

    it('superOwnerBalanceOfとsuperOwnerOfのエラー回収', async () => {
      await expect(collection.superOwnerBalanceOf(ethers.constants.AddressZero)).to.be.revertedWith('ERC721: address zero is not a valid owner');
      await expect(collection.superOwnerOf(BN(99))).to.be.revertedWith('ERC721: invalid token ID');
    });

    it('transferFromのエラー回収', async () => {
      await expect(collection.connect(lenderEOA).transferFrom(thirdEOA.address, lenderEOA.address, BN(1))).to.be.revertedWith('ERC721: transfer from incorrect superOwner');
      await expect(collection.connect(lenderEOA).transferFrom(lenderEOA.address, ethers.constants.AddressZero, BN(1))).to.be.revertedWith('ERC721: transfer to the zero address');
    });

    it('mintのエラー回収', async () => {
      await expect(collection.connect(lenderEOA).mint(ethers.constants.AddressZero, BN(4))).to.be.revertedWith('ERC721: mint to the zero address');
      await expect(collection.connect(lenderEOA).mint(thirdEOA.address, BN(1))).to.be.revertedWith('ERC721: token already minted');
    });
  });

  describe('トークンを貸出後に、lenderが別の人にtransferする', () => {
    it('貸出', async () => {
      network.provider.send('evm_mine');
      const blockNumber = await ethers.provider.getBlockNumber();
      const { timestamp } = await ethers.provider.getBlock(blockNumber);
      rentalExpireTime = timestamp + 300; // 5min
      const setOwnerFullfilled = await collection.connect(lenderEOA).setOwner(BN(1), renterEOA.address, rentalExpireTime);
      await (await setOwnerFullfilled).wait();
      expect(await collection.ownerOf(BN(1))).to.equal(renterEOA.address);
    });

    it('送付', async () => { //token 1
      const transfered = collection.connect(lenderEOA)['safeTransferFrom(address,address,uint256)'](lenderEOA.address, thirdEOA.address, BN(1));
      await (await transfered).wait();
      expect(await collection.ownerOf(BN(1))).to.equal(thirdEOA.address);
      expect(await collection.balanceOf(thirdEOA.address)).to.equal(BN(1));
      expect(await collection.superOwnerOf(BN(1))).to.equal(thirdEOA.address);
      expect(await collection.superOwnerBalanceOf(thirdEOA.address)).to.equal(BN(1));
    });
  });
});