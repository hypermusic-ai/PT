// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../concept/ConceptBase.sol";

contract ConceptA is ConceptBase
{
    string[]      private _composites   = ["Pitch", "Time"];
    
    constructor(address registryAddr) ConceptBase(registryAddr, "ConceptA", _composites)
    {
        opsCallDef().push(0, "Add", [uint32(1)]);
        opsCallDef().push(0, "Mul", [uint32(2)]);
        opsCallDef().push(0, "Nop");
        opsCallDef().push(0, "Add", [uint32(3)]);

        opsCallDef().push(1, "Add", [uint32(1)]);
        opsCallDef().push(1, "Add", [uint32(3)]);
        opsCallDef().push(1, "Add", [uint32(2)]);

        initOperands();
    }
}