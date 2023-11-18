import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("dotenv").config();

// set default for testing
const deployerKey = process.env.PRIVATE_KEY ??
  '0xabcd41dd92c1548cf7536c290e6a1871757fb5fea5721dea3a08c6d4abcd16cf';

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: false,
      chainId: 1337,
    },
    mumbai: {
      url: `https://polygon-mumbai.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [deployerKey],
      gasPrice: 35000000000
    },
    polygon: {
      url: `https://polygon-mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [deployerKey],
    },
  },
  etherscan: {
    apiKey: process.env.POLYGONSCAN_API_KEY,
  }

};

export default config;