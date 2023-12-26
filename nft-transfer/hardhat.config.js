require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200 // Adjust this number as needed
          }
        }
      },
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200 // Adjust this number as needed
          }
        }
      },
    ],
  },
  networks: {
    // for Base testnet
    baseSep: {
      url: 'https://sepolia.base.org',
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 1000000000,
    },
    opSep: {
      url: 'https://sepolia.optimism.io',
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 1000000000,
    },
  }
};
