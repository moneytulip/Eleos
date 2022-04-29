import { Contract } from "@ethersproject/contracts";
import { ethers } from "hardhat";

async function main() {
  const Ampl = await (
    await ethers.getContractFactory("Ampl")
  ).deploy(process.env.ADMIN_ADDRESS);

  logContractDeploy("Ampl", Ampl);

  await Ampl.deployed();

  const claimAggregator = await (
    await ethers.getContractFactory("ClaimAggregator")
  ).deploy();

  logContractDeploy("ClaimsAggregator", claimAggregator);

  await claimAggregator.deployed();

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
