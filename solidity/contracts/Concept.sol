// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "hardhat/console.sol";

import "./Ownable.sol";
import "./Operand.sol";
import "./Registry.sol";

interface IConcept is IOwnable
{
    function getName() external view returns(string memory);
    function isScalar() external view returns(bool);
    function getScalarsCount() external view returns (uint32);
    function getSubTreeSize() external view returns (uint32);
    function getCompositesCount() external view returns (uint32);
    function getComposite(uint32 id) external view returns (IConcept);
    function transform(uint32 dimId, uint32 opId, uint32 x) external view returns (uint32);
}

abstract contract ConceptBase is IConcept, Ownable
{
    IRegistry       private _registry;
    IConcept[]      private _composites;
    string          private _name;
    uint32          private _scalars;
    uint32          private _subTreeSize;
    IOperand[][]    private _operands;
    CallDef         private _operandsCallDef;
    //
    constructor(address registryAddr, string memory name, string[] storage compsNames)
    {
        assert(registryAddr != address(0));
        _registry = IRegistry(registryAddr);

        // find subconcepts
        for(uint8 i = 0; i < compsNames.length; ++i)
        {
            console.log("fetch concept ", compsNames[i], " - found: ", _registry.containsConcept(compsNames[i]));
            require(_registry.containsConcept(compsNames[i]), string.concat("cannot find composite concept: ", compsNames[i]));
            _composites.push(IConcept(_registry.conceptAt(compsNames[i])));
        }

        // allocate operands memory
        _operands = new IOperand[][](_composites.length);
        _operandsCallDef = new CallDef(_composites.length);

        // calculate scalars
        if(_composites.length == 0)
        {
            // scalar type
            _scalars = 1;
            _subTreeSize = 0;
        }
        else 
        {
            // composite type
            _scalars = 0;
            _subTreeSize = (uint32)(_composites.length);
            for(uint32 i=0; i < _composites.length; ++i)
            {
                _scalars += _composites[i].getScalarsCount();
                _subTreeSize += _composites[i].getSubTreeSize();
            }
        }
        assert(_scalars > 0);
        assert((_scalars == 1 && _composites.length == 0) 
            || (_scalars > 1 && _composites.length > 0));

        // set name
        _name = name;

        // register
        _registry.registerConcept(_name, address(this));
    }

    function opsCallDef() internal view returns (CallDef)
    {
        return _operandsCallDef;
    }

    function initOperands() internal
    {
        require(_operandsCallDef.getDimensionsCount() == _operands.length);

        for(uint8 dimId = 0; dimId < _operands.length; ++dimId)
        {
            uint32 opCount = _operandsCallDef.getOperandsCount(dimId);
            console.log("operands count ", opCount);

            for(uint8 opId = 0; opId < opCount; ++opId)
            {
                console.log("fetch operand ", _operandsCallDef.names(dimId, opId), 
                    " - found: ", _registry.containsOperand(_operandsCallDef.names(dimId, opId)));
                require(_registry.containsOperand(_operandsCallDef.names(dimId, opId)), 
                    string.concat("cannot find operand : ", _operandsCallDef.names(dimId, opId)));

                _operands[dimId].push(IOperand(_registry.operandAt(_operandsCallDef.names(dimId, opId))));
            }
        }
    }

    //
    function getName() external  view returns(string memory)
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
    function getSubTreeSize() external view returns (uint32)
    {
        return _subTreeSize;
    }

    //
    function getCompositesCount() external view returns (uint32)
    {
        return (uint32)(_composites.length);
    }

    //
    function getComposite(uint32 id) external view returns (IConcept)
    {
        require(id < _composites.length, "composite id out of range");
        return _composites[id];
    }

    //
    function transform(uint32 dimId, uint32 opId, uint32 x) external view returns (uint32)
    {
        require(dimId < _operands.length, "invalid dimension id");
        require(_operands[dimId].length != 0);
        
        opId %= (uint32)(_operands[dimId].length);
        uint32 out = _operands[dimId][opId].run(x, _operandsCallDef.getArgs(dimId, opId));
        return out;
    }
} 