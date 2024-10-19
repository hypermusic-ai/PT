// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "hardhat/console.sol";

import "./Ownable.sol";
import "./Registry.sol";

function nop(uint32 x) pure returns (uint32){
    return (x);
}

abstract contract Concept is Ownable
{
    Registry                                    private _registry;
    Concept[]                                   private _composites;
    string                                      private _name;
    uint32                                      private _scalars;
    function (uint32) pure returns (uint32)[][] private _ops;

    //
    constructor(address registryAddr, string memory name, string[] memory compsNames, function (uint32) pure returns (uint32)[][] memory ops)
    {
        assert(registryAddr != address(0));
        _registry = Registry(registryAddr);

        // find subconcepts
        for(uint8 i = 0; i < compsNames.length; ++i)
        {
            console.log("fetch ", compsNames[i], " - found: ", _registry.contains(compsNames[i]));
            require(_registry.contains(compsNames[i]), string.concat("cannot find composite concept: ", compsNames[i]));
            _composites.push(_registry.at(compsNames[i]));
        }

        // check operands
        _ops = ops;
        for(uint8 i = 0; i < _ops.length; ++i)
        {
            // should NEVER happen, that there are NO operands for dimension
            assert (_ops[i].length != 0);
        }

        // calculate scalars
        if(_composites.length == 0)
        {
            // scalar type
            _scalars = 1;
        }
        else 
        {
            // composite type
            _scalars = 0;
            for(uint32 i=0; i < _composites.length; ++i)
            {
                _scalars += _composites[i].getScalarsCount();
            }
        }
        assert(_scalars > 0);
        assert((_scalars == 1 && _composites.length == 0) 
            || (_scalars > 1 && _composites.length > 0));

        // set name
        _name = name;

        // register
        _registry.register(_name, this);
    }

    //
    function getName() external view returns(string memory)
    {
        return _name;
    }

    //
    function isScalar() external view returns(bool) 
    {
        return _composites.length == 0;
    }

    //
    function getScalarsCount() external view returns (uint32)
    {
        return _scalars;
    }

    //
    function getCompositesCount() external view returns (uint32)
    {
        return (uint32)(_composites.length);
    }

    //
    function getComposite(uint32 id) external view returns (Concept)
    {
        require(id < _composites.length, "composite id out of range");
        return _composites[id];
    }

    //
    function transform(uint32 dimId, uint32 opId, uint32 x) external view returns (uint32)
    {
        require(dimId < _ops.length, "invalid dimension id");
        assert (_ops[dimId].length != 0);
        
        opId %= (uint32)(_ops[dimId].length);
        uint32 out = _ops[dimId][opId](x);
        console.log("op[", opId, "]");
        console.log("f(", x, ") = ", out);
        return out;
    }
} 