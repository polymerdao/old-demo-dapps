// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require('hardhat');
const config = require('../config.json');

async function main() {
    const sendConfig = config.sendPacket;
    const accounts = await hre.ethers.getSigners();

    console.log(process.argv);

    const ibcAppSrc = await hre.ethers.getContractAt(
        `${config.srcContractType}`,
        sendConfig.srcAddr
    );

    // Do logic to prepare the packet

    const channelIdBytes = hre.ethers.encodeBytes32String(sendConfig.srcChannelId);
    const timeoutSeconds = sendConfig.timeout;
    // Send the packet
    await ibcAppSrc.connect(accounts[1]).sendCounterUpdate(
        channelIdBytes,
        timeoutSeconds        // add optional args here depending on the contract
    )
    let counter = await ibcAppSrc.counter();
    console.log(`Sending packet, counter before sending: ${counter}`);

    await new Promise((r) => setTimeout(r, 60000));

    counter = await ibcAppSrc.counter();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});