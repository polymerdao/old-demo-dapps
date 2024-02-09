// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require('hardhat');
const config = require('../config.json').sendUniversalPacket;

async function main() {
    const accounts = await hre.ethers.getSigners()

    const ibcBallot = await hre.ethers.getContractAt(
        'IbcBallot',
        config.srcAddr
    );

    const chairperson = await ibcBallot.chairperson();
    console.log('Owner: ' + chairperson)
    
    const voterAddr = accounts[1].address;
    // The very first time an account votes, the chairperson must give them the right to vote
    const voter = await ibcBallot.voters(voterAddr);

    if (voter.weight == 0) {
        await ibcBallot.connect(accounts[0]).giveRightToVote(voterAddr);
        console.log(`Chairperson gives right to vote to: ${voterAddr}`)
    }

    // To test the packet lifecycle multiple times using the same account, we need to reset the voter's state

    await ibcBallot.resetVoter(voterAddr);

    // Vote first before sending the packet
    await ibcBallot.connect(accounts[1]).vote(1);

    const recipient = voterAddr; // could be another account

    const channelIdBytes = hre.ethers.encodeBytes32String(config.srcChannelId);
    const timeoutSeconds = config.timeout;    

    // Send the packet
    await ibcBallot.sendMintNFTMsg(
        channelIdBytes,
        timeoutSeconds,
        voterAddr,
        recipient,
        config.dstAddr
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