// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require('hardhat');

const dispatcherAddr = '0xD92B86315CBcf9cC612F0b0542E0bE5871bCa146'
const ibcBallotAddress = '' // add when IbcBallot contract is deployed
const ibcProofOfVoteNFTAddr = '' // add when IbcProofOfVoteNFT is deployed on counterparty

function addressToPortId(portPrefix, address) {
  const suffix = address.slice(2);
  return `${portPrefix}.${suffix}`;
}

async function main() {

    const dispatcher = await hre.ethers.getContractAt(
        'IbcDispatcher',
        dispatcherAddr
    )

    const ibcBallot = await hre.ethers.getContractAt(
        'IbcBallot',
        ibcBallotAddress
    );

  const tx = await ibcBallot.createChannel(
    false,
    ['connection-2', 'connection-1'],
    {
        portId: `${addressToPortId('polyibc.base',ibcProofOfVoteNFTAddr)}`,
        channelId: hre.ethers.encodeBytes32String(''),
        version: '',
    },
    {
        proofHeight: { revision_height: 0, revision_number: 0 },
        proof: hre.ethers.encodeBytes32String('abc')
    }

  );

  await new Promise((r) => setTimeout(r, 60000));

  console.log(tx);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});