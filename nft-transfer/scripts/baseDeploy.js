const hre = require("hardhat");

async function main() {
    const baseDispatcher = '0xab6AEF0311954C40AcD4D1DED56CAAE9cc074975';
    const baseContract = await hre.ethers.deployContract("nftTransfer", [baseDispatcher, "BaseNFT", "BNFT"]);
    await baseContract.waitForDeployment();
    console.log(`nftTransfer deployed to ${baseContract.target}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
