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

// describe("I. Registering User", () => {
//     //   beforeEach(async () => {});

//     it("1. Addresses SHOULD be able to register themselves as users", async () => {
//       await expect(stack3.connect(signers[0]).registerUser(hashedSecret)).to
//         .eventually.be.fulfilled;
//     });
// })
