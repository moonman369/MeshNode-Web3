const { ethers } = require("hardhat");
const {
  deployStack3RareNFT,
  deployStack3Automation,
} = require("./deployFunctions");

const GAS_LANE =
  "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f";
const VRF_COO = "0x7a1bac17ccc5b313516c5e16fb24f7659aa5ebed";
const SUB_ID = 4746;
const CALL_BACK_GAS = "2500000";

const RARE_NFT_MAX_SUPPLY = 100;
const RARE_NFT_DROP_INTERVAL = 5 * 60;

// Change this value to valid Stack3.sol address during deployment';
const STACK3_ADDRESS = "0x5bdaf907D2c794D9Fa5D0bee5884191ADE9475A3";

const main = async () => {
  const [deployer] = await ethers.getSigners();
  // Stack3RareMint
  const COLLECTION_MINT_ADDRESS = /*"0x00000"*/ deployer.address;
  const RARE_NFT_BASE_URI = "URI/721/";

  const stack3RareNft = await deployStack3RareNFT(
    deployer.address,
    100,
    COLLECTION_MINT_ADDRESS,
    RARE_NFT_BASE_URI
  );

  const stack3Automation = await deployStack3Automation(
    deployer.address,
    VRF_COO,
    SUB_ID,
    GAS_LANE,
    CALL_BACK_GAS,
    RARE_NFT_DROP_INTERVAL,
    RARE_NFT_MAX_SUPPLY,
    stack3RareNft.address,
    STACK3_ADDRESS
  );

  await stack3RareNft.setApprovalForAll(stack3Automation.address, true);
  console.log(
    "Stack3Automation contract address has been approved for all Stack3RareMint Tokens.\n"
  );
};

main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => console.error(error));

/**
 * badges: 0x24C11d6d347DE57Bb435FFd66Ec7ECb960F11593
 * stack3: 0x5bdaf907D2c794D9Fa5D0bee5884191ADE9475A3
 * rare: 0x0d27b974Ee1B3a187C025656fABBC690e9463F01
 * auto: 0xb58863328Fa284a733aDF29a6D8f96F89a6b2eF1
 */
