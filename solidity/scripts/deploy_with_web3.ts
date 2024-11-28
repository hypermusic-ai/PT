// This script can be used to deploy the framework contracts using Web3 library.

import { deploy } from './web3-lib'

(async () => {
  try {
    const result = await deploy("contracts/registry",'RegistryBase', [])
    console.log(`address: ${result.address}`)
  } catch (e) {
    console.log(e.message)
  }

  try{
    const result = await deploy("contracts/runner", "Runner", [])
    console.log(`address: ${result.address}`)
  } catch (e) {
    console.log(e.message)
  }
})()