# Cross-chain voting/NFT app

This dApp combines the [ballot contract from the Solidity docs](https://docs.soliditylang.org/en/v0.8.23/solidity-by-example.html#voting) and the [NFT contract from the Base intro to smart contract developement](https://docs.base.org/guides/deploy-smart-contracts).

The aim is to enable cross-chain minting of the NFT contract corresponding to a vote cast on the ballot contract on the counterparty. Therefore we **make the contracts IBC enabled** by implementing the [`IbcReceiver` interface](https://github.com/open-ibc/vibc-core-smart-contracts/blob/main/contracts/IbcReceiver.sol) as specified by the vIBC protocol.

## Steps to interact with the dApp

>Note: It is recommended to use the `testing/x-ballot-nft` branch when testing channel handshakes and sending packets. The main branch represents more realistic voting behaviour (1 vote per account).

Follow these steps to test the dApp.

### Install dependencies & update config

When cloning the git repository, do:
```bash
npm install
```

In the `hardhat.config.js` file in the root directory, you'll see that you need to define 3 private keys (can be the same for OP and Base), in an `.env` file to load them as an environment variable to sign transactions.

### Update contract addresses in the scripts

The dispatcher contracts on Base and OP sepolia, as well as the (testing version) of the dApps have already been deployed and can be used for testing.

> If you want to experiment with the contracts you can recompile and deploy using the `deploy-<xyz>.js`` scripts.

You can find the deployed contract addresses here:

| - | OP Sepolia | Base Sepolia |
|-------------|-------------|-------------|
| Dispatcher | 0x7a1d713f80BFE692D7b4Baa4081204C49735441E | 0x749053bBFe3f607382Ac6909556c4d0e03D6eAF0 |
| IbcBallot | 0x85aCE263423343Ae57811A80872D55882E420366 | X |
| IbcProofOfVoteNFT | X | 0xA15c99eb3f52694bFfD57932dCa240552FCDCFfA |

**When using the default values, there's nothing you should do**, when using custom values update accordingly in the `create-channel-ballot.js` adn `vote-and-send.js` scripts.

### Create an IBC channel

You can test the channel handshake (triggered from the IbcBallot contract) by running:
```bash
npx hardhat run scripts/create-channel-ballot.js --network op-sepolia
```
Check the dispatcher contracts on either side to verify the successful completion of the handshake (alternatively query Polymer or the `connectedChannels` storage variable in the dApps).

### Send a packet

When the channel has been created, you can move to testing packet sends. Run:
```bash
npx hardhat run scripts/vote-and-send.js --network op-sepolia
```

Again check the dispatcher for evidence of succesful completion of the packet lifecycle or query Polymer or the dApp contracts to find out.
