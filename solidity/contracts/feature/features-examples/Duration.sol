// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../FeatureBase.sol";

import "../../condition/conditions-examples/AlwaysTrue.sol";

contract Duration is FeatureBase
{
    string[]      private _composites;

    constructor(address registryAddr) FeatureBase(registryAddr, new AlwaysTrue(), "Duration", _composites)
    {}
}