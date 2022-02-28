import { Contract } from "@ethersproject/contracts";
import { ethers } from "hardhat";

async function main() {
  const helper = await (
    await ethers.getContractFactory("DeployHelper")
  ).deploy();

  console.log(await helper.test());
  console.log('done');
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
