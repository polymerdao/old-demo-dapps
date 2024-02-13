// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require('hardhat');
const config = require('../config.json');
const chanConfig = config.createChannel;
const ibcConfig = require('../ibc.json');


function addressToPortId(portPrefix, address) {
  const suffix = address.slice(2);
  return `${portPrefix}.${suffix}`;
}

async function main() {
  const networkName = hre.network.name;
  
  let dispatcherAddr;
  if (networkName === 'optimism') {
    dispatcherAddr = process.env.OP_DISPATCHER;
  } else if (networkName === 'base') {
    dispatcherAddr = process.env.BASE_DISPATCHER;
  };
  
  const contractType = config["deploy"][`${networkName}`];

  const ibcAppSrc = await hre.ethers.getContractAt(
      `${contractType}`,
      chanConfig.srcAddr
  );
  
  const connHop1 = ibcConfig[chanConfig.srcChain].canonConnFrom;
  const connHop2 = ibcConfig[chanConfig.dstChain].canonConnTo;

  const tx = await ibcAppSrc.createChannel(
    chanConfig.version,
    chanConfig.ordering,
    chanConfig.fees,
    [ connHop1, connHop2 ],
    {
        portId: `${addressToPortId(`polyibc.${chanConfig.dstChain}`,chanConfig.dstAddr)}`,
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