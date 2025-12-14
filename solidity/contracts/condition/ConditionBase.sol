// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "./ICondition.sol";
import "../registry/IRegistry.sol";
import "../ownable/OwnableBase.sol";

abstract contract ConditionBase is ICondition, OwnableBase
{    
    IRegistry    private _registry;
    string      private _name;
    uint32      private _argc;

    constructor(address registryAddr, string memory name, uint32 argc)
    {
        require(registryAddr != address(0));
        _registry = IRegistry(registryAddr);
        
        _name = name;
        _argc = argc;

        _registry.registerCondition(_name, this);
    }

    function getArgsCount() external view returns(uint32)
    {
        return _argc;
    }
}