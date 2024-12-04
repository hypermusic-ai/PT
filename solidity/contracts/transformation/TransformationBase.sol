// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";

import "./ITransformation.sol";

import "../registry/IRegistry.sol";
import "../ownable/OwnableBase.sol";

abstract contract TransformationBase is ITransformation, OwnableBase
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

        _registry.registerTransformation(_name, this);
    }
    
    function getArgsCount() external view returns(uint32)
    {
        return _argc;
    }
}