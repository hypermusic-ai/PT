// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "hardhat/console.sol";
import "./Concept.sol";

function bytesToUint32Array(bytes memory input) pure returns (uint32[] memory) {
    // Ensure the length is a multiple of 4 (size of uint32)
    require(input.length % 4 == 0, "Invalid input length");
    uint32[] memory result = new uint32[](input.length / 4);
    for (uint256 i = 0; i < result.length; i++) {
        uint32 value;
        assembly {
            value := mload(add(input, add(0x20, mul(i, 0x4))))
        }
        result[i] = value;
    }
    return result;
}

contract Runner
{
    address private _registryAddr;

    constructor(address registryAddr) 
    {
        _registryAddr = registryAddr;
    }

    function gen(uint32 N, string memory conceptName) view external returns (uint32[] memory)
    {
        console.log("Runner gen");
        (bool sucess, bytes memory data) = _registryAddr.staticcall(abi.encodeWithSignature("at(string)", conceptName));
        require(sucess, "Call to Register::at() failed");
        address conceptAddr = abi.decode(data, (address));
        console.log("Fetched Concept from: ", conceptAddr);
        Concept concept = Concept(conceptAddr);

        uint32[] memory samples;
        for(uint32 i=0; i < N; ++i)
        {
            if(concept.isScalar())
            {

            }else 
            {
                //gen()
            }
        }
        //concept.composite();
        //for(IConcept composite)

        return (samples);
    }
}