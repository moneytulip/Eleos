# Eleos Core

This repository contains the core contracts of the Eleos Protocol.

Many design choices used in the Eleos Protocol stem from Impermax and UniswapV2. In order to understand the scope of this project and how it works we suggest the following readings:

- [Impermax x Uniswap V2 Whitepaper](https://impermax.finance/Whitepaper-Impermax-UniswapV2.pdf 'Impermax x Uniswap V2 Whitepaper'): this document explains the scope and the components of Impermax from a high level perspective.
- [UniswapV2 Whitepaper](https://uniswap.org/whitepaper.pdf 'UniswapV2 Whitepaper'): this document explains some design choices made while implementing UniswapV2.

## Local Deployment
npx hardhat run scripts/deployOracle.ts --network localhost
// Add to a .env or export addrs
npx hardhat run scripts/deploy.ts --network localhost


## Contracts on Oasis
- **EleosOracle** [0x5e8A25147e840C4F410EE33feEc4Ef96Db1A9063](https://explorer.emerald.oasis.dev/address/0x5e8A25147e840C4F410EE33feEc4Ef96Db1A9063#code)
- **BDeployer:** [0x012dF99b7aB3E13F1458B807a0aB4E1f7bb32fDC](https://explorer.emerald.oasis.dev/address/0x012dF99b7aB3E13F1458B807a0aB4E1f7bb32fDC#code)
- **CDeployer:** [0xC32aCe6aEE11342716A4Eb9efa98DC19E3184147](https://explorer.emerald.oasis.dev/address/0xC32aCe6aEE11342716A4Eb9efa98DC19E3184147#code)
- **Factory:** [0xeD9a19D1B62b00F945E64bE2d7d24D0c962fc9Ef](https://explorer.emerald.oasis.dev/address/0xeD9a19D1B62b00F945E64bE2d7d24D0c962fc9Ef#code)
- **Router:** [0xA987764B3133a2D6C9c6Cf4e9dFe45DeB1a056c7](https://explorer.emerald.oasis.dev/address/0xA987764B3133a2D6C9c6Cf4e9dFe45DeB1a056c7#code)

## Rinkeby
### Core Contracts
- **EleosOracle** [0xD1eb5077de2a4eF1f75941B5eA6ebfb5Cb0B0198](https://rinkeby.etherscan.io/address/0xD1eb5077de2a4eF1f75941B5eA6ebfb5Cb0B0198#code)
- **BDeployer:** [0xadB2a6273900C1facA83DA8624CcBA0887300201](https://rinkeby.etherscan.io/address/0xadB2a6273900C1facA83DA8624CcBA0887300201#code)
- **CDeployer:** [0x20fD0B2fbf1e499C4d41b1FdA8eF337992CF356B](https://rinkeby.etherscan.io/address/0x20fD0B2fbf1e499C4d41b1FdA8eF337992CF356B#code)
- **Factory:** [0x142E5E493c803852D51526c5556a0Ee2FAFAC0D9](https://rinkeby.etherscan.io/address/0x142E5E493c803852D51526c5556a0Ee2FAFAC0D9#code)
- **Router:** [0x5e8A25147e840C4F410EE33feEc4Ef96Db1A9063](https://rinkeby.etherscan.io/address/0x5e8A25147e840C4F410EE33feEc4Ef96Db1A9063#code)

### Governance Contracts on Rinkeby 
- **Amps:** [0xC32aCe6aEE11342716A4Eb9efa98DC19E3184147](https://rinkeby.etherscan.io/address/0xC32aCe6aEE11342716A4Eb9efa98DC19E3184147#code)
- **Claim Aggregator:** [0xeD9a19D1B62b00F945E64bE2d7d24D0c962fc9Ef](https://rinkeby.etherscan.io/address/0xeD9a19D1B62b00F945E64bE2d7d24D0c962fc9Ef#code)
- **Testing MasterChef:** [0xd40AE31bAa11147682be30948D6257573c2F2029](https://rinkeby.etherscan.io/address/0xd40AE31bAa11147682be30948D6257573c2F2029#code)


### Rinkeby Subgraph URLS: 
- Queries (HTTP):     https://api.thegraph.com/subgraphs/name/lilypad-forest/eleosrinkeby
- Subscriptions (WS): wss://api.thegraph.com/subgraphs/name/lilypad-forest/eleosrinkeby

## Deployment Procedure
Deploy oracle
Deploy core
Deploy router
