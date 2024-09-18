# [Solidity] Performative-Transactions

For Visual Studio Code, workspace `.vscode/solidity.code-worspace` is provided

## Commands

All commands are run from the `solidity` directory:

| Command                   | Action                                           |
| :------------------------ | :----------------------------------------------- |
| `npm install`             | Installs dependencies                            |
| `npx hardhat node`| start a local Ethereum network at `http://127.0.0.1:8545/` and provide you with some pre-funded accounts for testing|
| `npx hardhat compile` | To compile contracts |
| `npx hardhat run .\scripts\deploy_with_ethers.ts --network localhost` | deploy the framework contracts using [Ethers](https://docs.ethers.org/v5/) library |
| `npx hardhat run .\scripts\deploy_with_web3.ts --network localhost` | deploy the framework contracts using [Web3](https://web3js.readthedocs.io/en/v1.10.0) library |


## Structure

- `/contracts` Holds framework contracts.
- `/scripts` Contains scripts needed for contracts deploy.
- `/tests` Contains unit tests for PT framework.

## Docs

Documentation is available at https://pt-docs.netlify.app/