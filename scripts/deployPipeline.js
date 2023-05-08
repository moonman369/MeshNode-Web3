const { ethers } = require("hardhat");

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
    `Stack3 contract has been deployed at address: ${stack3RareMintNft.address}`
  );

  return stack3RareMintNft;
};

const deployStack3Badges = async (deployerAddress, baseUri) => {
  const deployer = await ethers.getSigner(deployerAddress);

  const Stack3Badges = await ethers.getContractFactory("Stack3Badges");

  const stack3Badges = await Stack3Badges.connect(deployer).deploy(baseUri);

  await stack3Badges.deployed();

  console.log(
    `Stack3 contract has been deployed at address: ${stack3Badges.address}`
  );

  return stack3Badges;
};

const deployStack3 = async (deployerAddress, stack3BadgesAddress) => {
  const deployer = await ethers.getSigner(deployerAddress);

  const Stack3 = await ethers.getContractFactory("Stack3");

  const stack3 = await Stack3.connect(deployer).deploy(stack3BadgesAddress);

  await stack3.deployed();

  console.log(
    `Stack3 contract has been deployed at address: ${stack3.address}`
  );

  return stack3;
};

const main = async () => {
  const [deployer] = await ethers.getSigners();

  const COLLECTION_MINT_ADDRESS = /*"0x00000"*/ deployer.address;
  const RARE_NFT_BASE_URI = "URI721/";
  const BADGES_BASE_URI = "URI1155/";

  const stack3RareNft = await deployStack3RareNFT(
    deployer.address,
    1000,
    COLLECTION_MINT_ADDRESS,
    RARE_NFT_BASE_URI
  );

  const stack3Badges = await deployStack3Badges(
    deployer.address,
    BADGES_BASE_URI
  );

  await deployStack3(deployer.address, stack3Badges.address);

  // await deployStack3(deployer.address, deployer.address, "BASE_URI", 0);
};

main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => console.error(error));

//  Deploys: {
//   1:
// }
