// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "./Ownable.sol";
import "./Registry.sol";

function nop(uint32 x) pure returns (uint32){
    return (x);
}

function next(uint32 x) pure returns (uint32){
    return (x + 1);
}

abstract contract Concept is Ownable
{
    bool private        _isScalar  = false;
    Registry private    _registry;
    address[] private   _compositesArr;

    constructor(address registryAddr, string memory name, string[] memory composites)
    {
        _registry = Registry(registryAddr);

        for(uint8 i = 0; i < composites.length; ++i)
        {
            _compositesArr.push(_registry.at(composites[i]));
        }
        if(_compositesArr.length == 0)
        {
            _isScalar = true;
        }
        _registry.register(name, this);
    }

    function transform(uint8 dimIdx, uint8 opIdx, uint32 x) virtual external view returns (uint32);
    function isScalar() external view returns(bool) {return _isScalar;}
} 