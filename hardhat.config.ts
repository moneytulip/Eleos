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
import { task } from "hardhat/config";
import { web3 } from "hardhat";
import { Contract } from "ethers";

task(
  "monitor_positions",
  "Computes all users current positions based on solidity events"
)
  .addParam("lendingPoolAddress", "The pool to track")
  .setAction(async (params) => {
    const filter = {
      address: params.lendingPoolAddress,
    };
    contract = new Contract(params.lendingPoolAddress, LendingPool.abi)
    // TODO query https://api.oasisscan.com/mainnet/swagger-ui/
    // Get transactions for user?
    //https://explorer.emerald.oasis.dev/api?module=logs&action=getLogs&fromBlock=5000&toBlock=latest&address=0xeD9a19D1B62b00F945E64bE2d7d24D0c962fc9Ef
  });

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
      gasPrice: 1000000000,
    },
    oasistest: {
      chainId: 42261,
      url: "https://testnet.emerald.oasis.dev",
      accounts: [process.env.OASIS_PRIV_KEY ?? ""],
    },
    oasis: {
      chainId: 42262,
      url: "https://emerald.oasis.dev",
      accounts: [process.env.OASIS_PRIV_KEY ?? ""],
    },
  },
};

export default config;
