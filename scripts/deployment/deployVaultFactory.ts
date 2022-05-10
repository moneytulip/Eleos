import { Contract } from "@ethersproject/contracts";
import { ethers } from "hardhat";

async function main() {
  const vaultFactory = await (
    await ethers.getContractFactory("VaultTokenFactory")
  ).deploy(
    process.env.UNISWAP_ROUTER_ADDRESS,
    process.env.MASTER_CHEF_ADDRESS,
    process.env.REWARDS_TOKEN_ADDRESS,
    901
  );

  logContractDeploy("Vault Factory", vaultFactory);

  await vaultFactory.deployed();

  console.log("Finished");
}

const logContractDeploy = (name: string, contract: Contract) => {
  console.log(`${name} address: ${contract.address}`);
  console.log(`${name} deploy tx hash: ${contract.deployTransaction.hash}`);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
