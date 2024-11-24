// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Pitch.sol";
import "./Time.sol";

import "../operands/Nop.sol";
import "../operands/Add.sol";
import "../operands/Mul.sol";

contract ConceptB is Concept
{
    string[]      private _composites   = ["Duration", "ConceptA"];

    constructor(address registryAddr) Concept(registryAddr, "ConceptB", _composites)
    {     
        // allocate space for operands for all composites
        CallDef ops = new CallDef(uint32(_composites.length));
  
        ops.allocate(0, 4); // allocate space for 4 operands for first composite
        ops.allocate(1, 3); // allocate space for 3 operand for second composite

        ops.set1(0, 0, "Add", [uint32(1)]);
        ops.set1(0, 1, "Mul", [uint32(2)]);
        ops.set0(0, 2, "Nop");
        ops.set1(0, 3, "Add", [uint32(3)]);

        ops.set1(1, 0, "Add", [uint32(1)]);
        ops.set1(1, 1, "Add", [uint32(3)]);
        ops.set1(1, 2, "Add", [uint32(2)]);

        initOperands(ops);
    }
}