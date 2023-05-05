const { ethers } = require("hardhat");

const deployStack3 = async (
  deployerAddress,
  tokenAddress,
  baseURI,
  reserverTokenCount
) => {
  const deployer = await ethers.getSigner(deployerAddress);

  const contractFactory = await ethers.getContractFactory("Stack3");

  const contractInstance = await contractFactory
    .connect(deployer)
    .deploy(tokenAddress, baseURI, reserverTokenCount);

  await contractInstance.deployed();

  console.log(
    `Stack3 contract has been deployed at address: ${contractInstance.address}`
  );
};

const main = async () => {
  const [deployer] = await ethers.getSigners();

  await deployStack3(deployer.address, deployer.address, "BASE_URI", 0);
};

main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => console.error(error));

//  Deploys: {
//   1:
// }
