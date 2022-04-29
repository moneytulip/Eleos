import { Contract } from "@ethersproject/contracts";
import { ethers } from "hardhat";

async function main() {
  const Ampl = await (
    await ethers.getContractFactory("Ampl")
  ).deploy();

  logContractDeploy("Ampl", Ampl);

  await Ampl.deployed();

  const claimsAggregator = await (
    await ethers.getContractFactory("ClaimsAggregator")
  ).deploy();

  logContractDeploy("ClaimsAggregator", claimsAggregator);

  await claimsAggregator.deployed();

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
