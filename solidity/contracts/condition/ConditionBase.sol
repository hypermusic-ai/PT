// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "hardhat/console.sol";

import "./ICondition.sol";

import "../registry/IRegistry.sol";
import "../ownable/OwnableBase.sol";

abstract contract ConditionBase is ICondition, OwnableBase
{    
    function update() override virtual external
    {

    }

    function check() override virtual external view returns(bool)
    {
        return true;
    }
}