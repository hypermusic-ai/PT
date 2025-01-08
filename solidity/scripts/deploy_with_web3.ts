// This script can be used to deploy the framework contracts using Web3 library.

import { deploy } from './web3-lib'

(async () => {

  const contracts = [
    ["contracts/registry","RegistryBase"],
    ["contracts/runner", "Runner"]
  ];

  for(const contract of contracts){
    try {
      const result = await deploy(contract[0], contract[1], [])
      console.log(`address: ${result.address}`)
    }catch(e)
    {
      console.log(e.message);
    }
  }
})()