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
      allowUnlimitedContractSize: true,
      gasPrice: 1000000000
    },
    oasistest: {
      chainId: 42261,
      url: "https://testnet.emerald.oasis.dev",
      accounts: [process.env.OASIS_PRIV_KEY ?? ''],
    },
    oasis: {
      chainId: 42262,
      url: "https://emerald.oasis.dev",
      accounts: [process.env.OASIS_PRIV_KEY ?? ''],
    },
    rinkeby: {
      chainId: 4,
      url: "https://rinkeby.infura.io/v3/30afe1c89595488cb279b0d8558064a8",
      accounts: [process.env.OASIS_PRIV_KEY ?? ''],
    }
  },
};

export default config;
