import { Contract } from "@ethersproject/contracts";
import { ethers } from "hardhat";
import fetch from "cross-fetch";
import { HttpLink } from "apollo-link-http";
import { ApolloClient, InMemoryCache, gql } from "@apollo/client/core";
import moment from "moment";

const client = new ApolloClient({
  link: new HttpLink({
    uri: "https://api.thegraph.com/subgraphs/name/lilypad-forest/eleosrinkeby",
    fetch: fetch,
  }) as any,
  cache: new InMemoryCache(),
});

// TODO: paginate through users
const borrowPositionQuery = `
  query UserPage($offset: Int, $limit: Int) {
    users(skip: $offset, first: $limit) {
    id
    borrowPositions(where: {borrowBalance_gt: 0.0}) {
      id
      borrowable {
        id
        lendingPool {
          collateral {
            id
            underlying {
              id
              syncCount
              isVaultToken
            }
          }
        }
        underlying {
          id
          symbol
        }
      }
      borrowIndex
      borrowBalance
    }
  }
}`;

const BN = ethers.BigNumber;

const SECS_IN_HOUR = 3600;

const toWei = (amount: Number, decimal = 18) => {
  return BN.from(amount).mul(BN.from(10).pow(BN.from(decimal)));
};

async function main() {
  const CollateralFactory = await ethers.getContractFactory("Collateral");
  const Erc20Factory = await ethers.getContractFactory(
    "@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20"
  );
  const RouterFactory = await ethers.getContractFactory("Router02");
  const router = await RouterFactory.attach(
    "0x5e8A25147e840C4F410EE33feEc4Ef96Db1A9063"
  );

  // Get user borrow positions
  // For each non-zero position, find corresponding collateral C
  // Call C.accountLiquidity(user) to get shortfall s
  // If s > 0, then we can liquidate

  const PAGE_SIZE = 25;
  const processPage = async (pageNumber: number) => {
    console.log(`Processing page ${pageNumber}`);
    const offset = pageNumber * PAGE_SIZE;
    return client
      .query({
        query: gql(borrowPositionQuery),
        variables: {
          limit: 25,
          offset,
        },
      })
      .then((response) => {
        if (response.data.users.length === 0) {
          throw new Error("EXHAUSTED_PAGES");
        }
        return response.data.users.filter((user: any) => {
          return user.borrowPositions.length;
        });
      })
      .then((users) =>
        users
          .map((user: any) =>
            user.borrowPositions.map(async (position: any) => {
              const collateralAddr =
                position.borrowable.lendingPool.collateral.id;
              const collateral = await CollateralFactory.attach(collateralAddr);
              // const tx = await collateral.accountLiquidity(user.id);
              // await tx.wait();
              // console.log('Processed liquidity calc tx');
              const { liquidity, shortfall } =
                await collateral.callStatic.accountLiquidity(user.id);
              return { ...position, liquidity, shortfall, user: user };
            })
          )
          .flat()
      )
      .then(async (queries) => {
        const out = [];
        for await (const q of queries) {
          if (BN.from(q.shortfall).gt(0.0)) {
            out.push(q);
          }
        }
        return out;
      })
      .then(async (shortfalls) =>
        shortfalls.map(async (shorty: any) => {
          const underlying = await Erc20Factory.attach(
            shorty.borrowable.underlying.id
          );
          const liquidatorUnderlyingBalance = await underlying.balanceOf(
            process.env.ADMIN_ADDRESS ?? ""
          );
          const shortfall = shorty.shortfall;
          const liquidationAmount = shortfall.lt(liquidatorUnderlyingBalance)
            ? shortfall
            : liquidatorUnderlyingBalance;
          const approve = await underlying.approve(
            router.address,
            liquidationAmount,
            { from: process.env.ADMIN_ADDRESS ?? "" }
          );
          console.log(
            "Initiating approval for liquidator's underlying",
            approve
          );
          await approve.wait();
          console.log("Initiating liquidation", shorty);
          const tx = await router.liquidate(
            shorty.borrowable.id,
            BN.from(liquidationAmount),
            shorty.user.id,
            process.env.ADMIN_ADDRESS,
            moment().unix() + SECS_IN_HOUR
          );
          await tx.wait();
          console.log("Completed Liquidated tx:", tx);
          return tx;
        })
      )
      .then(async (liquidationRequests) => {
        const out = [];
        for await (const tx of liquidationRequests) {
          out.push(tx);
        }
        return out;
      });
  };

  let pagesExhausted = false;
  let page = 0;
  while (!pagesExhausted) {
    await processPage(page).catch((err) => {
      if (err.message === "EXHAUSTED_PAGES") {
        pagesExhausted = true;
      } else {
        throw err;
      }
    });
    page++;
  }

  // Note: We run sequential otherwise the nonce gets fucked up
  // on the provider.

  // test
  // const collateral = await CollateralFactory.attach('0x10604cc77bc4fe3ef8e3220a8656c6903e7b6d1b');
  // const tx = await collateral.accountLiquidity('0x68a04b06cebf9c925a3c1128c23b56a8d074489a');
  // const out = await tx.wait();
  // console.log(tx);
  // const staticCall = await collateral.callStatic.accountLiquidity('0x68a04b06cebf9c925a3c1128c23b56a8d074489a');
  console.log("Finished");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
