import { Contract } from "@ethersproject/contracts";
import { ethers } from "hardhat";

async function main() {
  const bDeployer = await (
    await ethers.getContractFactory("BDeployer")
  ).deploy();
  const cDeployer = await (
    await ethers.getContractFactory("CDeployer")
  ).deploy();

  logContractDeploy("bDeployer", bDeployer);
  logContractDeploy("cDeployer", cDeployer);

  const amplifyFactory = await (
    await ethers.getContractFactory("Factory")
  ).deploy(
    process.env.ADMIN_ADDRESS,
    process.env.RESERVES_ADMIN_ADDRESS,
    bDeployer.address,
    cDeployer.address,
    process.env.PRICE_ORACLE_ADDRESS
  );

  logContractDeploy("factory", amplifyFactory);

  console.log("Awaiting deployment...");

  await bDeployer.deployed();
  await cDeployer.deployed();
  await amplifyFactory.deployed();

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
