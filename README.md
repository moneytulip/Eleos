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