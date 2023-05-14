const { ethers } = require("hardhat");
const {
  deployStack3RareNFT,
  deployStack3Automation,
} = require("./deployFunctions");

const GAS_LANE =
  "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61";
const VRF_COO = "0x2ed832ba664535e5886b75d64c46eb9a228c2610";
const SUB_ID = 658;
const CALL_BACK_GAS = "2500000";

const RARE_NFT_MAX_SUPPLY = 100;
const RARE_NFT_DROP_INTERVAL = 10 * 60;

const main = async () => {
  const [deployer] = await ethers.getSigners();
  // Stack3RareMint
  const COLLECTION_MINT_ADDRESS = /*"0x00000"*/ deployer.address;
  const RARE_NFT_BASE_URI = "URI/721/";

  const stack3RareNft = await deployStack3RareNFT(
    deployer.address,
    1000,
    COLLECTION_MINT_ADDRESS,
    RARE_NFT_BASE_URI
  );

  await deployStack3Automation(
    deployer.address,
    VRF_COO,
    SUB_ID,
    GAS_LANE,
    CALL_BACK_GAS,
    RARE_NFT_DROP_INTERVAL,
    RARE_NFT_MAX_SUPPLY,
    stack3RareNft.address
  );
};

main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => console.error(error));
