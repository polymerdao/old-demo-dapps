// This test script just makes sure the contract works internally for checking events being emmitted.
// there is not ibc testing here
const hre = require("hardhat");

async function main() {
    
    const ContractFactory = await hre.ethers.getContractFactory("nftTransfer");
    const contract = await ContractFactory.deploy();
    const [deployer] = await hre.ethers.getSigners();

    await contract.waitForDeployment();

    console.log(
        `contract deployed to ${contract.target}`
    );

    const ownerAddress = deployer.address;
    const destinationAddress = deployer.address;
    const memo = "hello world";
    const fee = {
        recvFee: 0,
        ackFee: 0,
        timeoutFee: 0,
    };
    contract.on("NFTMinted", (owner, tokenId) => {
        console.log(`NFTMinted event received: owner ${owner}, tokenId ${tokenId}`);
        contract.removeAllListeners("NFTMinted");
      });
    const mintTx = await contract.mintNFT(ownerAddress);

    await mintTx.wait();
    console.log('we have minted ');
    contract.on("NFTTransferred", (owner, tokenId, destinationAddress, data) => {
        console.log(`NFTTransferred event received: owner ${owner}, tokenId ${tokenId}, destinationAddress ${destinationAddress}, data ${data}`);
        contract.removeAllListeners("NFTTransferred");
    });
    const transferTx = await contract.initiateNFTTransfer("2", destinationAddress, memo, fee);
    await transferTx.wait();
    console.log('we have transfered ');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
