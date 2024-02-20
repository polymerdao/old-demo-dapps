# Demo dApps for Polymer

Welcome to the official repository for [Polymer](https://polymerlabs.org) demo applications! This repository serves as a centralized hub for the official (maintained by the Polymer Labs team and used in the official docs) demo apps, showcasing the capabilities and use cases of Polymer x [IBC](https://ibcprotocol.dev) interoperability.

### 🦸🏼🦸🏾‍♂️ Community projects 🦸🏾‍♀️🦸🏻

We highly encourage our community to build new demos and showcase them! To help visibility of these projects, they can be added to the [community demo dApps repo](https://github.com/polymerdevs/community-demo-dapps) in the PolymerDevs GitHub org.

## 📚 Documentation

There's some basic information here in the README but all of the dApps found here are documented more extensively in [the official Polymer documentation](https://docs.polymerlabs.org/docs/quickstart/).

## 📋 Prerequisites

The demo dapps repository has been based off of the project structure found in the [IBC app template for Solidity](https://github.com/open-ibc/ibc-app-solidity-template) so it has the same requirements:

- Have [git](https://git-scm.com/downloads) installed
- Have [node](https://nodejs.org) installed (v18+)
- Have [Foundry](https://book.getfoundry.sh/getting-started/installation) installed (Hardhat will be installed when running `npm install`)
- Have [just](https://just.systems/man/en/chapter_1.html) installed (recommended but not strictly necessary)

Some basic knowledge of all of these tools is also required, although the details are abstracted away for basic usage.

## 🧱 Repository Structure

This repository has a project structure that set it up to be compatible with the Hardhat and Foundry EVM development environments, as in the [IBC app template for Solidity repo](https://github.com/open-ibc/ibc-app-solidity-template). 

The main logic specific to the dApps can be found in the `/contracts` directory:
```bash
# Example tree structure with only one custom dApp, x-ballot-nft
contracts
├── XCounter.sol
├── XCounterUC.sol
├── base
│   ├── CustomChanIbcApp.sol
│   ├── GeneralMiddleware.sol
│   └── UniversalChanIbcApp.sol
├── x-ballot-nft
│   ├── XBallot.sol
│   └── XProofOfVoteNFT.sol
└── x-ballot-nft-UC
    ├── XBallotUC.sol
    └── XProofOfVoteNFTUC.sol
```

The `/contracts` directory always contains a `/base` directory where custom developed contract will inherit from to quickly get IBC compatibility. Additionally, you'll find the x-counter example from the IBC app template repo.

The additional folders are the custom developed applications.

## 🦮 Dependency management

This repo depends on Polymer's [vibc-core-smart-contracts](https://github.com/open-ibc/vibc-core-smart-contracts) which are tracked as git submodules. 

There are two ways to install these dependencies.

### Using Foundry

If you have Foundry installed, simply run:
```bash
forge install
```
to install the dependencies and:
```bash
forge update
```
to look for and install updates.

### Using git submodules directly

If you prefer not to use Foundry / Forge, you can use git submodules directly.

After cloning the repo, run this command additionally:
```bash
git submodule update --init --recursive
```

Find more documentation on using git submodules from the [official docs](https://git-scm.com/book/en/v2/Git-Tools-Submodules) or [in this tutorial](https://www.atlassian.com/git/tutorials/git-submodule).

## 🤝 Contributing

We welcome and encourage contributions from our community! Here’s how you can contribute.

### Option 1: Improve IBC Solidity app template

Have ideas how to improve the project environment itself, not just application logic? Feel free to drop an issue or a PR (after forking) in the [IBC app template for Solidity](https://github.com/open-ibc/ibc-app-solidity-template) repository.

### Option 2: Contribute to Polymer official demo-dapps

Have you seen an issue with any of the demo apps listed in this repo? Feel free to drop an issue or implement the changes yourself. Also if you feel you have a great addition that could live in the official docs, drop a PR and we'll investigate (it's possible we'll ask you to add it to the [community demo dApps repo](https://github.com/polymerdevs/community-demo-dapps) instead).

Please follow these steps when you do submit code changes:

1. **Fork the Repository:** Start by forking this repository.
2. **Add Your Demo App or make changes:** Place your demo app in the `/contracts` directory (separate directory for your project) or update the code that can be improved.
3. **Create a Pull Request:** Once you've added your demo or updated the code, create a pull request to the main repository with a detailed description of your app.

## 💡 Questions or Suggestions?

Feel free to open an issue for questions, suggestions, or discussions related to this repository. For further discussion as well as a showcase of some community projects, check out the [Polymer developer forum](https://forum.polymerlabs.org).

Thank you for being a part of our community!

