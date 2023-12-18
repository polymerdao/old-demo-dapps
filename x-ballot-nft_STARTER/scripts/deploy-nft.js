// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const dispatcherAddr = '0xab6AEF0311954C40AcD4D1DED56CAAE9cc074975';
  const tokenURI = 'https://cdn.discordapp.com/attachments/841255110721929216/1092765295388676146/bc19-4725-b503-d375e88692b3.png?ex=6581777d&is=656f027d&hm=39c445ad33e663dfa03c8c59a7f88a15cd02218490f97c5ec8ed96d11475c184&'
  
  const ibcNFT = await hre.ethers.deployContract("IbcProofOfVoteNFT", [dispatcherAddr, tokenURI]);

  await ibcNFT.waitForDeployment();

  console.log(
    `IbcProofOfVoteNFT deployed to ${ibcNFT.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
