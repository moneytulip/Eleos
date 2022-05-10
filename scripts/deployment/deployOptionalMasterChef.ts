import { Contract } from "@ethersproject/contracts";
import { ethers } from "hardhat";
const { makeUniswapV2Pair } = require("../test/Utils/Amplify");
const BN = ethers.BigNumber;

const { keccak256 } = require("ethers").utils;

const toWei = (amount: Number, decimal = 18) => {
  return BN.from(amount).mul(BN.from(10).pow(BN.from(decimal)));
};

async function deployUniswap() {
  const accounts = await ethers.getSigners();

  const weth = await (
    await ethers.getContractFactory("MockERC20")
  ).deploy("Wrapped ETH", "WETH");

  const t0 = await (
    await ethers.getContractFactory("MockERC20")
  ).deploy("T0", "T0");

  const t1 = await (
    await ethers.getContractFactory("MockERC20")
  ).deploy("T1", "T1");

  const factory = await (
    await ethers.getContractFactory("UniswapV2Factory")
  ).deploy(accounts[0].address);

  const router = await (
    await ethers.getContractFactory("UniswapV2Router02")
  ).deploy(factory.address, weth.address);

  await t0.mint(accounts[0].address, toWei(1e6));
  await t1.mint(accounts[0].address, toWei(1e6));

  await t0.approve(router.address, toWei(1e4));
  await t1.approve(router.address, toWei(1e4));

  await router.addLiquidity(
    t0.address,
    t1.address,
    toWei(1e4),
    toWei(1e4),
    0,
    0,
    accounts[0].address,
    16250578290
  );

  return { weth, t0, t1, factory, router };
}

async function main() {
  const accounts = await ethers.getSigners();

  let uniswapLPToken;
  if (!process.env.UNISWAP_ROUTER_ADDRESS) {
    let { t0, t1, factory, weth } = await deployUniswap();
    uniswapLPToken = await factory.getPair(t0.address, t1.address);
  } else {
    const router = await (
      await ethers.getContractFactory("UniswapV2Router02")
    ).attach(process.env.UNISWAP_ROUTER_ADDRESS);
    const factory = await ethers.getContractAt("UniswapV2Factory", await router.factory());
    uniswapLPToken = await factory.getPair(process.env.WETH_ADDRESS, process.env.AMPL_ADDRESS);
    console.log('the lp pair', uniswapLPToken);
  }
  // Setup masterchef
  const rewardsToken = await (
    await ethers.getContractFactory("SpookyToken")
  ).deploy();

  logContractDeploy("RewardsToken", rewardsToken);

  const masterChef = await (
    await ethers.getContractFactory("MasterChef")
  ).deploy(rewardsToken.address, accounts[0].address, toWei(1), 1651434126);
  // Rewards begin 1 May 2022

  logContractDeploy("MasterChef", masterChef);

  await masterChef.deployed();

  console.log('uhhh', uniswapLPToken);

  const initialised = (await masterChef.poolLength()).gt(0);

  console.log('hmmm', initialised, uniswapLPToken);

  if (!initialised) {
    await rewardsToken.transferOwnership(masterChef.address);
    await masterChef.add(3000, uniswapLPToken);
  }

  console.log('initialiseddddd');

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
