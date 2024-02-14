# Send a packet to sync cross-chain counter

This tutorial enables to send an IBC packet from an "Xcounter" contract on either OP or Base. The packet will ensure that a counter variable on either contract remains in sync.

## Install dependencies

To use the quickstart tutorial, make sure that you have all dependencies installed.

From the root directory of the demo-dapps repo, run:
```bash
git submodule update --init --recursive
```
and from the `x-counter` repository:
```bash
npm install
```

## Set up your environment variables

In the `.env` file (you'll find it as `.env.example`), add your private key(s) and rename to drop the "example" in the filename. The dispatcher addresses should be correct but you could use custom ones if required.

Next, check the `config.json` file. It is populated with values to send packets over channel-34 on Base or channel-15 on Optimism.

You can also choose to deploy your own Xcounter contracts and create a channel between them before sending packets over.

## Run the scripts

There's three types of scripts in the project:

- `deploy.js` and `deploy-config.js` allow you to deploy your application contract
- `create-channel.js` and `create-channel-config.js` creates a channel
- `send-packet.js` sends packets over an existing channel

For every script you'll find a field in the config.json!!

Make sure to update the config with the intended files before running one of the scripts like so:
```bash
npx hardhat run scripts/send-packet.js --network optimism
```

**NOTE** Make sure to align the `--network` flag value to be compatible with your config values either on optimism or base.

## Deploy

Run:
```bash
node scripts/deploy-config.js optimism base
```

To deploy instances of the contracts on optimism as the source and base as the destination chains. (You can also switch the order)

Also this script will take the output of the deployment and update the config file with all the relevant information.

Then run:
```bash
node scripts/create-channel-config.js
```

To create a channel between base and optimism. Note that the **ORDER MATTERS*; if you picked optimism as the source chain (first argument) above, by default it will create the channel from optimism and vice versa.

Also this script will take the output of the channel creation and update the config file with all the relevant information.

Check out the [channel tab in the explorer](https://explorer.prod.testnet.polymer.zone/channels) to find out if the correct channel-id's related to your contracts were updated in the config.

Finally run:
```bash
npx hardhat run scripts/send-packet.js --network optimism
```
to send a packet. You can pick either optimism or base to send the packet from.



