const { ethers } = require("hardhat");
require("dotenv").config();
const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const { BigNumber } = require("ethers");
const { requestMerkleSecret } = require("../merkle/setMerkleTree");
const { SECRET_PHRASE } = process.env;

const expect = chai.expect;
chai.use(chaiAsPromised);

let deployer, signers, addresses;
let stack3;
let stack3Badges;

const NULL_ADDRESS = "0x0000000000000000000000000000000000000000";

const BADGES_URI = "uri/badges/";
const POST_URI = "uri/post/";

const INIT_TAG_COUNT = 30;
const { hashedSecret, merkleRoot } = requestMerkleSecret(SECRET_PHRASE);
const provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545/");

before(async () => {
  [deployer, ...signers] = await ethers.getSigners();

  addresses = signers.map((signer) => signer.address);

  const Stack3Badges = await ethers.getContractFactory("Stack3Badges");
  stack3Badges = await Stack3Badges.connect(deployer).deploy(BADGES_URI);
  await stack3Badges.deployed();

  const Stack3 = await ethers.getContractFactory("Stack3");
  stack3 = await Stack3.connect(deployer).deploy(
    stack3Badges.address,
    INIT_TAG_COUNT,
    merkleRoot
  );
  await stack3.deployed();

  await stack3Badges.connect(deployer).setStack3Address(stack3.address);
});

describe(`========================================STACK3 BADGES========================================\n\n\nI. Question Rewards`, () => {
  // beforeEach(async () => {});
  const tags = [1, 2, 3, 4, 5];
  const postQuestion_X_n = async (n) => {
    for (let i = 0; i < n; i++) {
      await stack3
        .connect(signers[0])
        .postQuestion(tags, POST_URI, hashedSecret);
    }
  };

  it("1. Users SHOULD receive particular badge nft on posting 10 questions", async () => {
    await stack3.connect(signers[0]).registerUser(BADGES_URI, hashedSecret);
    await postQuestion_X_n(10);
    const badgeId_10Q = await stack3Badges.QUESTION_10();
    expect(await stack3Badges.balanceOf(addresses[0], badgeId_10Q)).to.eql(
      BigNumber.from(1)
    );
  });

  it("2. Users SHOULD receive particular badge nft on posting 25 questions", async () => {
    await postQuestion_X_n(25 - 10 /* = 15*/);
    const badgeId_25Q = await stack3Badges.QUESTION_25();
    expect(await stack3Badges.balanceOf(addresses[0], badgeId_25Q)).to.eql(
      BigNumber.from(1)
    );
  });

  it("3. Users SHOULD receive particular badge nft on posting 50 questions", async () => {
    await postQuestion_X_n(50 - 25 /* = 25*/);
    const badgeId_50Q = await stack3Badges.QUESTION_50();
    expect(await stack3Badges.balanceOf(addresses[0], badgeId_50Q)).to.eql(
      BigNumber.from(1)
    );
  });

  it("4. Users SHOULD receive particular badge nft on posting 100 questions", async () => {
    await postQuestion_X_n(100 - 50 /* = 50 */);
    const badgeId_100Q = await stack3Badges.QUESTION_100();
    expect(await stack3Badges.balanceOf(addresses[0], badgeId_100Q)).to.eql(
      BigNumber.from(1)
    );
  });
});
