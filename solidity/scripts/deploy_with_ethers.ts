// This script can be used to deploy framework contracts using ethers.js library.

import { deploy } from './ethers-lib'

(async () => {
  try {
    const result = await deploy('Registry', [])
    console.log(`address: ${result.address}`)
  } catch (e) {
    console.log(e.message)
  }
  try {
    const result = await deploy('Runner', [])
    console.log(`address: ${result.address}`)
  } catch (e) {
    console.log(e.message)
  }
})()