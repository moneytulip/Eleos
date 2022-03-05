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

- **BDeployer:** [0xD1eb5077de2a4eF1f75941B5eA6ebfb5Cb0B0198](https://explorer.emerald.oasis.dev/address/0x2217aec3440e8fd6d49a118b1502e539f88dba55#code)
- **CDeployer:** [0xadB2a6273900C1facA83DA8624CcBA0887300201](https://explorer.emerald.oasis.dev/address/0x46fcde1b89d61f5cbfaab05c2914c367f8301f30#code)
- **Factory:** [0x20fD0B2fbf1e499C4d41b1FdA8eF337992CF356B](https://explorer.emerald.oasis.dev/address/0x35c052bbf8338b06351782a565aa9aad173432ea#code)
