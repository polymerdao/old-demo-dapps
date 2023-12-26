const hre = require("hardhat");

async function main() {
    const opDispatcher = '0xD92B86315CBcf9cC612F0b0542E0bE5871bCa146';
    const opContract = await hre.ethers.deployContract("nftTransfer", [opDispatcher, "opNFT", "ONFT"]);
    await opContract.waitForDeployment();
    console.log(`nftTransfer deployed to ${opContract.target}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
