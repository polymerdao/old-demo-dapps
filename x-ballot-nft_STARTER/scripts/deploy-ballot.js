// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const dispatcherAddr = '0xD92B86315CBcf9cC612F0b0542E0bE5871bCa146';

  const proposalNames = ['0x506f6c796d6572206272696e67732049424320746f20457468657265756d0000', '0x506f6c796d6572206272696e67732049424320746f20616c6c206f6620746800'];
  const ibcBallot = await hre.ethers.deployContract("IbcBallot", [proposalNames, dispatcherAddr]);

  await ibcBallot.waitForDeployment();

  console.log(
    `IbcBallot deployed to ${ibcBallot.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});