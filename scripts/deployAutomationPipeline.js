const { ethers } = require("hardhat");
const {
  deployMeshNodeRareNFT,
  deployMeshNodeAutomation,
} = require("./deployFunctions");

const GAS_LANE =
  "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f";
const VRF_COO = "0x7a1bac17ccc5b313516c5e16fb24f7659aa5ebed";
const SUB_ID = 4746;
const CALL_BACK_GAS = "2500000";

const RARE_NFT_MAX_SUPPLY = 30;
const RARE_NFT_DROP_INTERVAL = 5 * 60;

// Change this value to valid MeshNode.sol address during deployment';
const MESHNODE_ADDRESS = "0x5bdaf907D2c795D0bee5884191ADE9475A3";

const main = async () => {
  const [deployer] = await ethers.getSigners();
  // MeshNodeRareMint
  const COLLECTION_MINT_ADDRESS = /*"0x00000"*/ deployer.address;
  const RARE_NFT_BASE_URI =
    "https://hackathon.mypinata.cloud/ipfs/QmbANiYSXZHnCrpXK9KK8JqWB3HViS2imnPkYi6pYU8hXd/";

  const meshNodeRareNft = await deployMeshNodeRareNFT(
    deployer.address,
    100,
    COLLECTION_MINT_ADDRESS,
    RARE_NFT_BASE_URI
  );

  const meshNodeAutomation = await deployMeshNodeAutomation(
    deployer.address,
    VRF_COO,
    SUB_ID,
    GAS_LANE,
    CALL_BACK_GAS,
    RARE_NFT_DROP_INTERVAL,
    RARE_NFT_MAX_SUPPLY,
    meshNodeRareNft.address,
    MESHNODE_ADDRESS
  );

  await meshNodeRareNft.setApprovalForAll(meshNodeAutomation.address, true);
  console.log(
    "MeshNodeAutomation contract address has been approved for all MeshNodeRareMint Tokens.\n"
  );
};

main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => console.error(error));

/**
 * badges: 0x24C11d6d347DE57Bb435FFd66Ec7ECb960F11593
 * meshNode: 0x5bdaf907D2c794D9Fa5D0bee5884191ADE9475A3
 * rare: 0x52796D14B1B8101527E9CF1eC2A27124FECa13eF
 * auto: 0x14a8dB8CCA62551657a3175F2ee9Ae256aB93876
 */
