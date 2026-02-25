// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./ITransformation.sol";
import "../registry/IRegistry.sol";
import "../ownable/OwnableBase.sol";

abstract contract TransformationBase is ITransformation, OwnableBase
{
    IRegistry    private _registry;
    string      private _name;
    uint32      private _argc;

    function __TransformationBase_init(address registryAddr, string memory name, uint32 argc) internal onlyInitializing {
        require(registryAddr != address(0));
        __OwnableBase_init(msg.sender);

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
