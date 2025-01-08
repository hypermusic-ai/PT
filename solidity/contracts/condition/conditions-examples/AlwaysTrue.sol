// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../ConditionBase.sol";

contract AlwaysTrue is ConditionBase
{
    constructor() 
    {}

    function check() override external pure returns(bool)
    {
        return true;
    }
}