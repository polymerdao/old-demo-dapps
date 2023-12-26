const hre = require('hardhat');

const nftBaseAddress = '0x411Ba9e0c76650C938866AbAad5b3d73de43Ea26' //
const ownerAddress = '0x03dE63ce87402e9B98725972D522aB97873208e3';
const receiverAddress = '0x0C72cdF3771eC7000D9Fa67C5aE61C6113Ae1C37';

async function main() {


    const nftBase = await hre.ethers.getContractAt(
        'nftTransfer',
        nftBaseAddress
    );
    nftBase.on("NFTTransferred", (from, tokenId, to, memo) => {
        console.log("NFT Transferred - Token ID:", tokenId);
        console.log("From:", from);
        console.log("To:", to);
        console.log("Memo:", memo);
    });
    const transferTx = await nftBase.initiateNFTTransfer(2, receiverAddress, "Hey here's a memo", {
        gasLimit: 500000
    });
    const receipt = await transferTx.wait();
    console.log(transferTx);
    
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});