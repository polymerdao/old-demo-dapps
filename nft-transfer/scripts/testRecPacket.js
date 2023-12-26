const hre = require('hardhat');

const ownerAddress = '0x03dE63ce87402e9B98725972D522aB97873208e3';
const receiverAddress = '0x0C72cdF3771eC7000D9Fa67C5aE61C6113Ae1C37';
const baseDispatcher = '0xab6AEF0311954C40AcD4D1DED56CAAE9cc074975';

async function main() {
    const [deployer] = await ethers.getSigners();
    let IbcPacket = {
        src: {
            portId: 'poly.ibc.yadadada',
            channelId: hre.ethers.encodeBytes32String('channel-1')
        },
        dest: {
            portId: 'poly.ibc.yadadada',
            channelId: hre.ethers.encodeBytes32String('channel-2')
        },
        sequence: 64,
        data: '0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002800000000000000000000000000000000000000000000000000000000000000300000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb922660000000000000000000000000c72cdf3771ec7000d9fa67c5ae61c6113ae1c3700000000000000000000000000000000000000000000000000000000000003a00000000000000000000000000000000000000000000000000000000000000042307830303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b68747470733a2f2f696d6775722e636f6d2f612f78526d5338684100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001b68747470733a2f2f696d6775722e636f6d2f612f78526d53386841000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002754686520666972737420657665722063726f737320636861696e20506f6c796d6572204e4654210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046d656d6f00000000000000000000000000000000000000000000000000000000',
        timeoutHeight: {
            revision_number: 1,
            revision_height: 1111
        },
        timeoutTimestamp: 44
    }

    const baseContract = await hre.ethers.deployContract("nftTransfer", [baseDispatcher, "BaseNFT", "BNFT"]);
    await baseContract.waitForDeployment();
    
    baseContract.on("NFTMinted", async (owner, tokenId) => {
        console.log("NFTMinted event received! ", owner, tokenId);
    });
    baseContract.on("NFTLocked", async (owner, tokenId) => {
        console.log("NFTLocked event received! ", owner, tokenId);
    });
    baseContract.on("NFTUnlocked", async (owner, tokenId) => {
        console.log("NFTUnlocked event received! ", owner, tokenId);
    });
    
    baseContract.on("NFTTransferred", async (from, tokenId, to, payload) => {
        IbcPacket.data = payload;
        console.log("NFTTransferred event received! Sending the packet...");
        baseContract.on("packetTest", (data) => {
            console.log("packetTest event received! ");
        });
        const recvTx = await baseContract.onRecvPacket(IbcPacket);
        const receipt2 = await recvTx.wait();
        // console.log(recvTx);
        // console.log(receipt2);
        console.log("Packet sent!");
    });
    // console.log(`nftTransfer deployed to ${baseContract.target}`);
    const mintTx = await baseContract.mintNFT(deployer.address);
    const mintTxReceipt = await mintTx.wait();


    const encodedData = await baseContract.initiateNFTTransfer(1, receiverAddress, "memo");
    const receipt1 = await encodedData.wait();

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});