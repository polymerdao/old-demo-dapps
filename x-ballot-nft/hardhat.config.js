require("@nomicfoundation/hardhat-toolbox");

require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: '0.8.20',
  },
  networks: {
    // for Base testnet
    'base-sepolia': {
      url: 'https://sepolia.base.org',
      accounts: [
        process.env.WALLET_KEY_1,
        process.env.WALLET_KEY_2,
        process.env.WALLET_KEY_3
      ],
      //gasPrice: 1000000000,
    },
    // for OP testnet
    'op-sepolia': {
      url: 'https://sepolia.optimism.io',
      accounts: [
        process.env.WALLET_KEY_1, 
        process.env.WALLET_KEY_2, 
        process.env.WALLET_KEY_3
      ],
      //gasPrice: 1000000000,
    },    
  },
  defaultNetwork: 'hardhat',
};