const { expect } = require("chai");
const { ethers } = require("hardhat");

const deploySock = async () => {
  const SockPuppetSupperClub = await ethers.getContractFactory("SockPuppetSupperClub");
  const nft = await SockPuppetSupperClub.deploy(
    3,
    2,
    100,
    "0x6277a1073DFBE0Ea087E0eF8741DCE084831E782",
    "https://foo.com/"
  );
  await nft.deployed();
  return nft;
};

describe("SockPuppetSupperClub", () => {
  it("Should work", async () => {
    const nft = await deploySock();
    expect(await nft.royalty()).to.equal(100);
  });

  it("Shouldnt allow minting until its time", async () => {
    const nft = await deploySock();

    await expect(nft.craft(1)).to.be.revertedWith("It's still nap time. Settle down");

    await nft.setStartBlock(1);

    await nft.craft(1, { value: 2 });
  });

  it("Shouldnt allow minting withoutn the right amount of dosh", async () => {
    const nft = await deploySock();

    await nft.setStartBlock(1);

    await expect(nft.craft(1)).to.be.revertedWith("Ether value sent is not sufficient. Socks aint cheap!");

    await nft.craft(1, { value: 2 });
    await nft.craft(2, { value: 4 });
  });

  it("Should only allow minting to the numbah", async () => {
    const nft = await deploySock();

    await nft.setStartBlock(1);

    await nft.craft(3, { value: 6 });
    await expect(nft.craft(1, { value: 2 })).to.be.revertedWith("We ran out of socks! Bummer");
  });

  it("Should only allow batch minting to the numbah", async () => {
    const nft = await deploySock();

    await nft.setStartBlock(1);

    await nft.craft(2, { value: 4 });
    await expect(nft.craft(2, { value: 4 })).to.be.revertedWith("Mmmm this is a nice edge case");
  });

  it("Gives correct royalties", async () => {
    const nft = await deploySock();

    const firstRoyaltyInfo = await nft.royaltyInfo(1, 500);
    const secondRoyaltyInfo = await nft.royaltyInfo(1, 99); // rounds down

    console.log(firstRoyaltyInfo.royaltyAmount.toString());
    console.log(secondRoyaltyInfo.receiver);

    expect(firstRoyaltyInfo.receiver).to.equal("0x6277a1073DFBE0Ea087E0eF8741DCE084831E782");
    expect(firstRoyaltyInfo.royaltyAmount.toString()).to.eq("5");

    expect(secondRoyaltyInfo.receiver).to.equal("0x6277a1073DFBE0Ea087E0eF8741DCE084831E782");
    expect(secondRoyaltyInfo.royaltyAmount.toString()).to.eq("0"); 
  });

  it("Handles baseuris correctly", async () => {
    const nft = await deploySock();

    await nft.setStartBlock(1);

    await nft.craft(2, { value: 4 });

    const tokenUri = await nft.tokenURI(1);
    const secondOne = await nft.tokenURI(2);

    expect(tokenUri).to.equal("https://foo.com/1");
    expect(secondOne).to.equal("https://foo.com/2");
  });

  it("Withdraws", async () => {
    const nft = await deploySock();

    await nft.setStartBlock(1);

    await nft.craft(3, { value: 6 });

    await nft.withdrawAll();

    const balance = await ethers.provider.getBalance("0x6277a1073DFBE0Ea087E0eF8741DCE084831E782");

    expect(balance.toString()).to.equal("6");

  });
});
