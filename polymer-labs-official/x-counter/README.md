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

In the `.env` file (you'll find it as `.env.example`), add your private key(s). The dispatcher addresses should be correct but you could use custom ones if required.

Next, check the `config.json` file. It is populated with values to send packets over channel-16 on Base or channel-17 on Optimism.

You can also choose to deploy your own Xcounter contracts and create a channel between them before sending packets over.

## Run the scripts

There's three scripts in the project:

- `deploy.js` allows you to deploy your application contract
- `create-channel.js` creates a channel
- `send-packet.js` sends packets over an existing channel

For every script you'll find a field in the config.json!!

Make sure to update the config with the intended files before running one of the scripts like so:
```bash
npx hardhat run scripts/send-packet.js --network op-sepolia
````

**NOTE** Make sure to align the `--network` flag value to be compatible with your config values either on optimism (op-sepolia) or base (base-sepolia).



