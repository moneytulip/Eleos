import { Contract } from "@ethersproject/contracts";
import { ethers } from "hardhat";

async function main() {
  const router = await (
    await ethers.getContractFactory("Router")
  ).deploy(
    process.env.FACTORY_ADDRESS,
    process.env.BDEPLOYER_ADDRESS,
    process.env.CDEPLOYER_ADDRESS,
    process.env.WETH_ADDRESS,
  );

  logContractDeploy("cDeployer", router);

  await router.deployed();

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
