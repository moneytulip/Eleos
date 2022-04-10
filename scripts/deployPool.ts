import { Contract } from "@ethersproject/contracts";
import { ethers } from "hardhat";
import Factory from "../artifacts/contracts/Factory.sol/Factory.json";

async function main() {

  const factory = await ethers.getContractAt(Factory.abi, process.env.FACTORY_ADDRESS ?? '');
  const wRoseTulipSwapPool = "0x08B3BdE2e398B0840c76C78D42bd26B3412706B9";
  
  await factory.createCollateral(wRoseTulipSwapPool);
  await factory.createBorrowable0(wRoseTulipSwapPool);
  await factory.createBorrowable1(wRoseTulipSwapPool);

  console.log("Created collateral and borrowables");

  await factory.initializeLendingPool(wRoseTulipSwapPool);

  console.log("Initialised pool");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
