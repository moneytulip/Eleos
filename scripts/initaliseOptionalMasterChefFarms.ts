import { Contract } from "@ethersproject/contracts";
import { ethers } from "hardhat";
const BN = ethers.BigNumber;

const toWei = (amount: Number, decimal = 18) => {
  return BN.from(amount).mul(BN.from(10).pow(BN.from(decimal)));
};

async function main() {
  const accounts = await ethers.getSigners();

  const masterChef = await (
    await ethers.getContractFactory("MasterChef")
  ).attach("0xd40AE31bAa11147682be30948D6257573c2F2029");

  const rewardsToken = await (
    await ethers.getContractFactory("SpookyToken")
  ).attach("0x945b2348f0E6cCD524552718425D938bcaA99C78");

  const amplWethLP = await (
    await ethers.getContractFactory("UniswapV2Pair")
  ).attach("0x15fcd2C34816C610b061cb7C6d5140A94368B7D9")

  // Deposit some LP
  const initialised = (await masterChef.poolLength()).gt(0);
  console.log(initialised);
  const b = await amplWethLP.balanceOf(accounts[0].address);
  await amplWethLP.approve(masterChef.address, toWei(b));
  console.log('lp bal: ', b.toString());
  // await masterChef.deposit(0, toWei(1));
  // await masterChef.withdraw(0, toWei(1));
  // console.log('depo', b, await masterChef.pendingBOO(0, accounts[0].address));
  // console.log('hmm', await masterChef.poolLength());
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
