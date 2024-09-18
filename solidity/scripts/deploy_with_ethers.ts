// This script can be used to deploy framework contracts using ethers.js library.

import { deploy } from './ethers-lib'

(async () => {
  try {
    const registryResult = await deploy('Registry', [])
    const registryAddr = await registryResult.getAddress();
    console.log(`Registry deployed at address: ${registryAddr}`)

    const runnerResult = await deploy('Runner', [registryAddr])
    const runnerAddr = await runnerResult.getAddress();

    console.log(`Runner deployed at address: ${runnerAddr}`)

  } catch (e) {
    console.log(e.message)
  }
  try {

  } catch (e) {
    console.log(e.message)
  }
})()