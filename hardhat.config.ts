import * as dotenv from "dotenv";
dotenv.config();
import {
  HardhatUserConfig,
  HttpNetworkConfig,
  HttpNetworkHDAccountsConfig,
} from "hardhat/types";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-truffle5";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      gasPrice: 1000
    },
    oasistest: {
      chainId: 42261,
      url: "https://testnet.emerald.oasis.dev",
      accounts: [process.env.OASIS_PRIV_KEY],
    },
    oasis: {
      chainId: 42262,
      url: "https://emerald.oasis.dev",
      accounts: [process.env.OASIS_PRIV_KEY],
    },
  },
};

export default config;
