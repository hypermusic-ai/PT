// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Pitch.sol";
import "./Time.sol";

import "../operands/nop.sol";
import "../operands/add.sol";
import "../operands/mul.sol";

contract ConceptA is ConceptBase
{
    string[]      private _composites   = ["Pitch", "Time"];
    
    constructor(address registryAddr) ConceptBase(registryAddr, "ConceptA", _composites)
    {
        opsCallDef().push1(0, "Add", [uint32(1)]);
        opsCallDef().push1(0, "Mul", [uint32(2)]);
        opsCallDef().push0(0, "Nop");
        opsCallDef().push1(0, "Add", [uint32(3)]);

        opsCallDef().push1(1, "Add", [uint32(1)]);
        opsCallDef().push1(1, "Add", [uint32(3)]);
        opsCallDef().push1(1, "Add", [uint32(2)]);

        initOperands();
    }
}