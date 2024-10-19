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
    string[] private composites = ["Duration", "ConceptA"];
    function (uint32) pure returns (uint32)[][] ops = [[op3, op4], [op3, op4]];
    
    constructor(address registryAddr) Concept(registryAddr, "ConceptB", composites, ops)
    {}
}