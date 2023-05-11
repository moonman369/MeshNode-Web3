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

const INIT_TAG_COUNT = 30;
const { hashedSecret, merkleRoot } = requestMerkleSecret(SECRET_PHRASE);

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

describe("I. Registering User", () => {
  //   beforeEach(async () => {});

  it("1. Addresses SHOULD be able to register themselves as users", async () => {
    await expect(stack3.connect(signers[0]).registerUser(hashedSecret)).to
      .eventually.be.fulfilled;
  });

  it("2. Registered User struct SHOULD have reqd parameters set to initial value", async () => {
    const {
      id,
      bestAnswerCount,
      qUpvotes,
      aUpvotes,
      userAddress,
      questions,
      answers,
      comments,
    } = await stack3.getUserByAddress(addresses[0]);

    expect(id).to.eql((await stack3.getTotalCounts())[0]);
    expect(bestAnswerCount).to.eql(BigNumber.from(0));
    expect(qUpvotes).to.eql(BigNumber.from(0));
    expect(aUpvotes).to.eql(BigNumber.from(0));
    expect(userAddress).to.equal(addresses[0]);
    expect(questions).to.eql([]);
    expect(answers).to.eql([]);
    expect(comments).to.eql([]);
  });

  it("3. Addresses SHOULD receive a User Badge NFT after sucessful registration.", async () => {
    const userBadgeTokenId = await stack3Badges.USER();
    expect(await stack3Badges.balanceOf(addresses[0], userBadgeTokenId)).to.eql(
      BigNumber.from(1)
    );
  });

  it("4. Addresses already registered as User SHOULD NOT be able to call.", async () => {
    await expect(
      stack3.connect(signers[0]).registerUser(hashedSecret)
    ).to.eventually.be.rejectedWith("Stack3: User already registered");
  });

  it("5. Function SHOULD not execute if invalid secret is passed", async () => {
    const { hashedSecret: invalidSecret } =
      requestMerkleSecret("NOT-VALID-PHRASE");
    await expect(
      stack3.connect(signers[0]).registerUser(invalidSecret)
    ).to.eventually.be.rejectedWith("Stack3: Unverified source of call");
  });
});

describe("II. Posting questions.", () => {
  beforeEach(() => {
    stack3.connect(signers[0]).registerUser(hashedSecret);
  });
});
