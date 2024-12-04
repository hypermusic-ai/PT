// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../feature/FeatureBase.sol";

contract Time is FeatureBase
{
    string[]      private _composites;

    constructor(address registryAddr) FeatureBase(registryAddr, "Time", _composites)
    {}
}