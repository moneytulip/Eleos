import { Contract } from "@ethersproject/contracts";
import { ethers } from "hardhat";
const BN = ethers.BigNumber;

const toWei = (amount: Number, decimal = 18) => {
  return BN.from(amount).mul(BN.from(10).pow(BN.from(decimal)));
};

async function createStakedLendingPool(vaultToken: string) {
  const amplifyFactory = await ethers.getContractAt(
    "Factory",
    process.env.FACTORY_ADDRESS ?? ""
  );

  let tx;
  // tx = await amplifyFactory.createCollateral(vaultToken);
  // console.log(tx);
  // await tx.wait();
  const lendingPool = await amplifyFactory.getLendingPool(vaultToken);
  // console.log('Lending pool', lendingPool);
  // tx = await amplifyFactory.createBorrowable0(vaultToken);
  // await tx.wait();
  // console.log('B0')
  // tx = await amplifyFactory.createBorrowable1(vaultToken);
  // await tx.wait();
  // console.log('B1')
  // tx = await amplifyFactory.initializeLendingPool(vaultToken);

  const oracle = await ethers.getContractAt(
    "AmplifyPriceOracle",
    "0xD1eb5077de2a4eF1f75941B5eA6ebfb5Cb0B0198"
  );
  
  const vaultTokenInstance = await ethers.getContractAt(
    "VaultToken",
    vaultToken
  );

  const accounts = await ethers.getSigners();

  const amplWethLP = await (
    await ethers.getContractFactory("UniswapV2Pair")
  ).attach("0x15fcd2C34816C610b061cb7C6d5140A94368B7D9")
  const b = await amplWethLP.balanceOf(accounts[0].address);

  console.log('lp bal: ', b.toString());

  // await vaultTokenInstance.mint(accounts[0].address)
  // tx = await oracle.initialize(lendingPool);
  // await tx.wait();

  await amplWethLP.transfer(vaultToken, toWei(1));

  console.log("initialised pool", await vaultTokenInstance.mint(accounts[0].address));
}

// This initialises some staked LP lending pools
async function main() {
  const vaultFactory = await ethers.getContractAt(
    "VaultTokenFactory",
    process.env.VAULT_TOKEN_FACTORY_ADDRESS ?? ""
  );

  // await vaultFactory.createVaultToken(0);
  const vaultToken = await vaultFactory.getVaultToken(0);

  await createStakedLendingPool(vaultToken);

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
