// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require('hardhat');

const ibcBallotAddress = '0x6e65AA34035D87f341E17b49be995ee0C50A505c' // add ibcBallot address when deployed
const IbcProofOfVoteNFTAddr = '0x04bD80D9bAbFC15Cb8411965A750b38cB8266eDf'

async function main() {
    const accounts = await hre.ethers.getSigners()

    const ibcBallot = await hre.ethers.getContractAt(
        'IbcBallot',
        ibcBallotAddress
    );
    
    const voterAddr = accounts[2].address;

    // Vote first before sending the packet
    await ibcBallot.connect(accounts[2]).vote(1);

    const recipient = voterAddr; // could be another account

    // Send the packet
    await ibcBallot.sendMintNFTMsg(
        voterAddr,
        recipient,
        IbcProofOfVoteNFTAddr
    )
    console.log(`Sending packet to mint NFT for ${recipient} relating to vote cast by ${voterAddr}`)

    // Active waiting for the packet to be received and acknowledged
    let acked = false;
    let counter = 0;
    do {
        const updatedVoter = await ibcBallot.voters(voterAddr);
        acked = updatedVoter.ibcNFTMinted;
        if (!acked) {
            console.log("ack not received. waiting...");
            await new Promise((r) => setTimeout(r, 2000));
            counter++;
        } 
    } while (!acked && counter<100);
    
    console.log("Packet lifecycle was concluded successfully: " + acked);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});