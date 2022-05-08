import { Contract } from "@ethersproject/contracts";
import { ethers } from "hardhat";
import fetch from 'cross-fetch';
import { HttpLink } from 'apollo-link-http';
import {
  ApolloClient,
  InMemoryCache,
  gql
} from "@apollo/client/core";

const client = new ApolloClient({
  link: new HttpLink({
    uri: 'https://api.thegraph.com/subgraphs/name/lilypad-forest/eleosrinkeby',
    fetch: fetch
  }) as any,
  cache: new InMemoryCache()
});

// TODO: paginate through users
const borrowPositionQuery = `{
  users(first: 100) {
    id
    borrowPositions(where: {borrowBalance_gt: 0.0}) {
      id
      borrowable {
        lendingPool {
          collateral {
            id
            underlying {
              syncCount
              isVaultToken
            }
          }
        }
        underlying {
          symbol
        }
      }
      borrowIndex
      borrowBalance
    }
  }
}`

async function main() {
  const CollateralFactory = await ethers.getContractFactory("Collateral");
  
  // Get user borrow positions 
  // For each non-zero position, find corresponding collateral C
  // Call C.accountLiquidity(user) to get shortfall s
  // If s > 0, then we can liquidate


  // Note: We run sequential otherwise the nonce gets fucked up 
  // on the provider.
  const querySets = await client.query({
    query: gql(borrowPositionQuery)
  }).then(response => response.data.users.filter((user: any) => {
    return user.borrowPositions.length
  })).then(users => users.map((user: any) => user.borrowPositions.map(async (position: any) => {
      const collateralAddr = position.borrowable.lendingPool.collateral.id;
      const collateral = await CollateralFactory.attach(collateralAddr);
      // const tx = await collateral.accountLiquidity(user.id);
      // await tx.wait();
      // console.log('Processed liquidity calc tx');
      const staticShortfall = await collateral.callStatic.accountLiquidity(user.id);
      console.log('mmmk', staticShortfall);
      return staticShortfall;
    })
  ));

  for (const queries of querySets) {
    for (const query of queries) {
      console.log('Preparing to query for shortfall');
      const shorty = await query;
      console.log(shorty);
    }
  }

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
