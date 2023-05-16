const { ethers } = require("hardhat");
require("dotenv").config();
// const { requestMerkleSecret } = require("../merkle/setMerkleTree");

const deployStack3RareNFT = async (
  deployerAddress,
  maxSupply,
  collectionMintAddress,
  baseUri
) => {
  const deployer = await ethers.getSigner(deployerAddress);

  const Stack3RareMintNFT = await ethers.getContractFactory(
    "Stack3RareMintNFT"
  );

  const stack3RareMintNft = await Stack3RareMintNFT.connect(deployer).deploy(
    maxSupply,
    collectionMintAddress,
    baseUri
  );

  await stack3RareMintNft.deployed();

  console.log(
    `Stack3RareMintNFT contract has been deployed at address: ${stack3RareMintNft.address}\n`
  );

  return stack3RareMintNft;
};

const deployStack3Badges = async (deployerAddress, baseUri) => {
  const deployer = await ethers.getSigner(deployerAddress);

  const Stack3Badges = await ethers.getContractFactory("Stack3Badges");

  const stack3Badges = await Stack3Badges.connect(deployer).deploy(baseUri);

  await stack3Badges.deployed();

  console.log(
    `Stack3Badges contract has been deployed at address: ${stack3Badges.address}\n`
  );

  return stack3Badges;
};

const deployStack3 = async (
  deployerAddress,
  stack3BadgesAddress,
  initTagCount,
  merkleRoot
) => {
  const deployer = await ethers.getSigner(deployerAddress);

  const Stack3 = await ethers.getContractFactory("Stack3");

  const stack3 = await Stack3.connect(deployer).deploy(
    stack3BadgesAddress,
    initTagCount,
    merkleRoot
  );

  await stack3.deployed();

  console.log(
    `Stack3 contract has been deployed at address: ${stack3.address}\n`
  );

  return stack3;
};

const deployStack3Automation = async (
  deployerAddress,
  vrfCoordinatorV2,
  subId,
  gasLane,
  callbackGasLimit,
  dropInterval,
  maxSupply,
  rareNftAddress
) => {
  const deployer = await ethers.getSigner(deployerAddress);

  const Stack3Automation = await ethers.getContractFactory("Stack3Automation");

  const stack3Automation = await Stack3Automation.connect(deployer).deploy(
    vrfCoordinatorV2,
    subId,
    gasLane,
    callbackGasLimit,
    dropInterval,
    maxSupply,
    rareNftAddress
  );

  await stack3Automation.deployed();

  console.log(
    `Stack3Automation contract has been deployed at address: ${stack3Automation.address}\n\n`
  );

  return stack3Automation;
};

module.exports = {
  deployStack3,
  deployStack3Badges,
  deployStack3RareNFT,
  deployStack3Automation,
};
