// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Pitch.sol";
import "./Time.sol";

function op3(uint32 x) pure returns (uint32){
    return (x + 3);
}

function op4(uint32 x) pure returns (uint32){
    return (x - 2);
}

contract ConceptB is Concept
{
    uint8 constant D = 2;
    string[] private composites = ["Duration", "ConceptA"];
    function (uint32) pure returns (uint32)[][D] ops = [[op3, op4], [op3, op4]];
    
    constructor(address registryAddr) Concept(registryAddr, "ConceptB", composites)
    {
    }

    function transform(uint8 dimIdx, uint8 opIdx, uint32 x) override external view returns (uint32)
    {
        assert(dimIdx < D);
        return ops[dimIdx][opIdx](x);
    }
}