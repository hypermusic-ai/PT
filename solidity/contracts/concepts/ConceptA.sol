// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Pitch.sol";
import "./Time.sol";

function op0(uint32 x) pure returns (uint32){
    return (x + 1);
}

function op1(uint32 x) pure returns (uint32){
    return (x * 2);
}

function op2(uint32 x) pure returns (uint32){
    return (x ** 2);
}

contract ConceptA is Concept
{
    string[] private composites = ["Pitch", "Time"];
    function (uint32) pure returns (uint32)[][] ops = [[op0, op1, nop], [op0, op1, op2]];
    
    constructor(address registryAddr) Concept(registryAddr, "ConceptA", composites, ops)
    {}
}