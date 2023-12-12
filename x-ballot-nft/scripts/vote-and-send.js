// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require('hardhat');

const ibcBallotAddress = '0xd3cEB4716C9231A4C8b7B2bB2dC2b44F4F742b74' // add ibcBallot address when deployed

async function main() {
    const accounts = await hre.ethers.getSigners()

    const ibcBallot = await hre.ethers.getContractAt(
        'IbcBallot',
        ibcBallotAddress
    );
    const chairperson = await ibcBallot.chairperson();
    console.log('Owner ' + chairperson)

    const fee = {
        recvFee: 0,
        ackFee: 0,
        timeoutFee: 0,
    };

    const tx = await ibcBallot.connect(accounts[0]).giveRightToVote(accounts[1].address);
    console.log(`Chairperson gives right to vote to: ${accounts[1].address}`)

    const vote_tx = await ibcBallot.connect(accounts[1]).vote(1);

    const recipient = accounts[1].address; // could be another account

    const send_tx = await ibcBallot.sendMintNFTMsg(
        accounts[1].address,
        recipient,
        fee
    )
    console.log(`Sending packet to mint NFT for ${recipient} relating to vote cast by ${accounts[1].address}`)

    await new Promise((r) => setTimeout(r, 120000));
    
    const voter = await ibcBallot.voters(accounts[1].address);
    const acked = voter.ibcNFTMinted;
    console.log("Packet lifecycle was concluded successfully: " + acked);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});