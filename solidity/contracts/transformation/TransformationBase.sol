// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./ITransformation.sol";
import "../registry/IRegistry.sol";
import "../ownable/OwnableConstructorBase.sol";

abstract contract TransformationBase is ITransformation, OwnableConstructorBase
{
    IRegistry    private _registry;
    string      private _name;
    uint32      private _argc;

    constructor(address registryAddr, string memory name, uint32 argc)
        OwnableConstructorBase(msg.sender)
    {
        require(registryAddr != address(0), "registry is zero");

        _registry = IRegistry(registryAddr);
        _name = name;
        _argc = argc;

        IRegistry.TransformationRegistration memory registration = IRegistry.TransformationRegistration({
            owner: msg.sender,
            argsCount: _argc
        });

        _registry.registerTransformation(_name, this, registration);
    }
    
    function getArgsCount() external view returns(uint32)
    {
        return _argc;
    }
}
