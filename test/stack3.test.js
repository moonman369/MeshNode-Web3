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

describe("I. Registering User", () => {
  //   beforeEach(async () => {});

  it("1. Addresses SHOULD be able to register themselves as users", async () => {
    await expect(stack3.connect(signers[0]).registerUser(hashedSecret)).to
      .eventually.be.fulfilled;
  });

  it("2. Registered User struct SHOULD have reqd params set to initial values", async () => {
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

  it("5. Function SHOULD NOT execute if invalid secret is passed", async () => {
    const { hashedSecret: invalidSecret } =
      requestMerkleSecret("NOT-VALID-PHRASE");
    await expect(
      stack3.connect(signers[0]).registerUser(invalidSecret)
    ).to.eventually.be.rejectedWith("Stack3: Unverified source of call");
  });
});

describe("II. Posting questions", () => {
  const tagsParam = [1, 5, 7, 8, 3, 9].map((tag) => BigNumber.from(tag));
  beforeEach(async () => {
    stack3.connect(signers[0]).registerUser(hashedSecret);
  });

  it("1. Registered users SHOULD be able to post Questions.", async () => {
    await expect(
      stack3.connect(signers[0]).postQuestion(tagsParam, hashedSecret)
    ).to.eventually.be.fulfilled;
  });

  it("2. Question authors User state must be updated accordingly", async () => {
    const { questions } = await stack3.getUserByAddress(addresses[0]);
    const newQID = questions[questions.length - 1];
    expect(questions.length).to.equal(1);
    expect(newQID).to.eql((await stack3.getTotalCounts())[0]);
  });

  it("3. A Question struct SHOULD have reqd params set to initial values", async () => {
    const { questions } = await stack3.getUserByAddress(addresses[0]);
    const newQID = questions[questions.length - 1];
    // console.log(newQID);

    const {
      bestAnswerChosen,
      id,
      upvotes,
      downvotes,
      author,
      tags,
      comments,
      answers,
    } = await stack3.getQuestionById(newQID);

    expect(bestAnswerChosen).to.equal(false);
    expect(id).to.eql(newQID);
    expect(upvotes).to.eql(BigNumber.from(0));
    expect(downvotes).to.eql(BigNumber.from(0));
    expect(author).to.equal(addresses[0]);
    expect(tags).to.eql(tagsParam);
    expect(comments).to.eql([]);
    expect(answers).to.eql([]);
  });

  it("4. Unregistered addresses SHOULD NOT be able to call the function", async () => {
    await expect(
      stack3.connect(signers[1]).postQuestion(tagsParam, hashedSecret)
    ).to.eventually.be.rejectedWith("Stack3: User not registered");
  });

  it("5. Users SHOULD NOT be able to pass more than 10 tags per question.", async () => {
    const gt10Tags = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    await expect(
      stack3.connect(signers[0]).postQuestion(gt10Tags, hashedSecret)
    ).to.eventually.be.rejectedWith("Stack3: Max tag count is 10");
  });

  it("6. Function SHOULD NOT execute if invalid secret is passed", async () => {
    const { hashedSecret: invalidSecret } =
      requestMerkleSecret("NOT-VALID-PHRASE");
    await expect(
      stack3.connect(signers[0]).postQuestion(tagsParam, invalidSecret)
    ).to.eventually.be.rejectedWith("Stack3: Unverified source of call");
  });
});

describe("III. Vote on question", () => {
  const tagsParam = [1, 5, 7, 8, 3, 9].map((tag) => BigNumber.from(tag));
  let QID;
  beforeEach(async () => {
    stack3.connect(signers[0]).registerUser(hashedSecret);

    stack3.connect(signers[1]).registerUser(hashedSecret);
    stack3.connect(signers[2]).registerUser(hashedSecret);

    stack3.connect(signers[0]).postQuestion(tagsParam, hashedSecret);
    const { questions } = await stack3.getUserByAddress(addresses[0]);
    QID = questions[questions.length - 1];
  });

  const up1down1 = async (qId) => {
    await stack3.connect(signers[1]).voteQuestion(qId, 1, hashedSecret);
    await stack3.connect(signers[2]).voteQuestion(qId, -1, hashedSecret);
  };

  it("1. A User SHOULD be able upvote or downvote a question", async () => {
    await expect(stack3.connect(signers[1]).voteQuestion(QID, 1, hashedSecret))
      .to.eventually.be.fulfilled;
    await expect(stack3.connect(signers[2]).voteQuestion(QID, -1, hashedSecret))
      .to.eventually.be.fulfilled;
  });

  it("2. Upvotes and downvote count SHOULD be reflected in Question struct", async () => {
    await up1down1(QID);
    // console.log(await stack3.getQuestionById(QID));
    const { upvotes, downvotes } = await stack3.getQuestionById(QID);
    expect(upvotes).to.eql(BigNumber.from(1));
    expect(downvotes).to.eql(BigNumber.from(1));
  });

  it("3. Upvotes count SHOULD be reflected in User struct", async () => {
    const { author } = await stack3.getQuestionById(QID);
    const { qUpvotes: qUpInit } = await stack3.getUserByAddress(author);

    await up1down1(QID);

    const { qUpvotes: qUpFinal } = await stack3.getUserByAddress(author);

    expect(qUpFinal).to.eql(qUpInit.add(1));
  });

  it("4. Unregistered addresses SHOULD NOT be able to call the function", async () => {
    await expect(
      stack3.connect(signers[3]).voteQuestion(QID, 1, hashedSecret)
    ).to.eventually.be.rejectedWith("Stack3: User not registered");
  });

  it("5. Function SHOULD NOT execute for invalid `questionId` param passed", async () => {
    await expect(
      stack3.connect(signers[1]).voteQuestion(QID.add(200), -2, hashedSecret)
    ).to.eventually.be.rejectedWith("Stack3: Invalid question id");
  });

  it("6. Function SHOULD NOT execute for invalid `voteMarker` param passed", async () => {
    await expect(
      stack3.connect(signers[1]).voteQuestion(QID, -2, hashedSecret)
    ).to.eventually.be.rejectedWith("Stack3: Invalid vote param");
  });

  it("6. User SHOULD NOT be able to call function more than once per QID", async () => {
    await up1down1(QID);

    await expect(
      stack3.connect(signers[1]).voteQuestion(QID, 1, hashedSecret)
    ).to.eventually.be.rejectedWith("Stack3: User has voted");
  });

  it("7. Function SHOULD NOT execute if invalid secret is passed", async () => {
    const { hashedSecret: invalidSecret } =
      requestMerkleSecret("NOT-VALID-PHRASE");
    await expect(
      stack3.connect(signers[0]).voteQuestion(QID, 1, invalidSecret)
    ).to.eventually.be.rejectedWith("Stack3: Unverified source of call");
  });
});
