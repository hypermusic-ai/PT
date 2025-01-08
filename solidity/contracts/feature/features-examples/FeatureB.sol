// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../FeatureBase.sol";

import "../../condition/conditions-examples/Counter.sol";

contract FeatureB is FeatureBase
{
    string[]      private _composites   = ["Duration", "FeatureA"];

    constructor(address registryAddr) FeatureBase(registryAddr, new Counter(5), "FeatureB", _composites)
    {       
        getCallDef().push(0, "Add", [uint32(1)]);
        getCallDef().push(0, "Mul", [uint32(2)]);
        getCallDef().push(0, "Nop");
        getCallDef().push(0, "Add", [uint32(3)]);

        getCallDef().push(1, "Add", [uint32(1)]);
        getCallDef().push(1, "Add", [uint32(3)]);
        getCallDef().push(1, "Add", [uint32(2)]);

        initTransformations();
    }
}