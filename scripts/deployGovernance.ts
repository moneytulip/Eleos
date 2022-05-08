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

  const supplyVaultRouter01 = await (
    await ethers.getContractFactory("SupplyVaultRouter01")
  ).deploy(
    process.env.WETH_ADDRESS,
  );
  logContractDeploy("SupplyVaultRouter01", supplyVaultRouter01);
  await supplyVaultRouter01.deployed();

  const strategy = await (
    await ethers.getContractFactory("SupplyVaultStrategyV3")
  ).deploy();
  logContractDeploy("SupplyVaultStrategyV3", strategy);
  await strategy.deployed();

  const supplyVault = await (
    await ethers.getContractFactory("SupplyVault")
  ).deploy(
    Ampl.address,
    strategy.address,
    "Staked Amplify",
    "xAMPL",
  );
  logContractDeploy("SupplyVault", supplyVault);
  await supplyVault.deployed();

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
