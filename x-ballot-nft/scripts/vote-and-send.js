// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require('hardhat');

const ibcBallotAddress = '0x85aCE263423343Ae57811A80872D55882E420366' // add ibcBallot address when deployed

async function main() {
    const accounts = await hre.ethers.getSigners()

    const ibcBallot = await hre.ethers.getContractAt(
        'IbcBallot',
        ibcBallotAddress
    );
    const chairperson = await ibcBallot.chairperson();
    console.log('Owner ' + chairperson)

    const voterAddr = accounts[1].address;
    const voter = await ibcBallot.voters(voterAddr);

    await ibcBallot.resetVoter(voterAddr);

    if (voter.weight == 0) {
        const tx = await ibcBallot.connect(accounts[0]).giveRightToVote(voterAddr);
        console.log(`Chairperson gives right to vote to: ${voterAddr}`)
    }

    await ibcBallot.connect(accounts[1]).vote(1);

    const recipient = voterAddr; // could be another account

    const fee = {
        recvFee: 0,
        ackFee: 0,
        timeoutFee: 0,
    };

    await ibcBallot.sendMintNFTMsg(
        voterAddr,
        recipient,
        fee
    )
    console.log(`Sending packet to mint NFT for ${recipient} relating to vote cast by ${voterAddr}`)


    for (var i = 0; i < 10; i++) {
        try {
            const acked = voter.ibcNFTMinted;
            console.log("Packet lifecycle was concluded successfully: " + acked);
            break
        } catch {
            console.log("ack not received. waiting...");
            await new Promise((r) => setTimeout(r, 2000));
        }
    }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
