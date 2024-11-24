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
    uint32                                      private _subTreeSize;
    Operand[][]                                 private _operands;
    uint32[][][]                                private _operandsArgs;

    //
    constructor(address registryAddr, string memory name, string[] storage compsNames)
    {
        assert(registryAddr != address(0));
        _registry = Registry(registryAddr);

        // find subconcepts
        for(uint8 i = 0; i < compsNames.length; ++i)
        {
            console.log("fetch concept ", compsNames[i], " - found: ", _registry.containsConcept(compsNames[i]));
            require(_registry.containsConcept(compsNames[i]), string.concat("cannot find composite concept: ", compsNames[i]));
            _composites.push(_registry.conceptAt(compsNames[i]));
        }

        // allocate operands memory
        _operands = new Operand[][](_composites.length);
        _operandsArgs = new uint32[][][](_composites.length);

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
        _registry.registerConcept(_name, this);
    }

    function initOperands(CallDef ops) internal
    {
        require(ops.getDimensionsCount() == _operands.length);

        for(uint8 dimId = 0; dimId < _operands.length; ++dimId)
        {
            uint32 opCount = ops.getOperandsCount(dimId);
            console.log("operands count ", opCount);

            _operandsArgs[dimId] = new uint32[][](opCount);
            for(uint8 opId = 0; opId < opCount; ++opId)
            {
                console.log("fetch operand ", ops.names(dimId, opId), " - found: ", _registry.containsOperand(ops.names(dimId, opId)));
                require(_registry.containsOperand(ops.names(dimId, opId)), string.concat("cannot find operand : ", ops.names(dimId, opId)));

                _operands[dimId].push(_registry.operandAt(ops.names(dimId, opId)));

                uint32 argc = ops.getArgsCount(dimId, opId);
                for(uint8 argId = 0; argId < argc; ++argId)
                {
                    _operandsArgs[dimId][opId].push(ops.args(dimId, opId, argId));
                }
            }
        }
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
    function getComposite(uint32 id) external view returns (Concept)
    {
        require(id < _composites.length, "composite id out of range");
        return _composites[id];
    }

    //
    function transform(uint32 dimId, uint32 opId, uint32 x) public view returns (uint32)
    {
        require(dimId < _operands.length, "invalid dimension id");
        require(_operands[dimId].length != 0);
        
        opId %= (uint32)(_operands[dimId].length);
        uint32 out = _operands[dimId][opId].run(x, _operandsArgs[dimId][opId]);
        return out;
    }

    function generateSubconceptSpace(uint32 dimId, uint32 start, uint32 N) public view returns (uint32[] memory)
    {
        require(dimId < _operands.length, "invalid dimension id");

        uint32[] memory space = new uint32[](N);

        uint32 x = start;
        for(uint32 opId = 0; opId < N; ++opId)
        {
            space[opId] = x;
            x = this.transform(dimId, opId, x);
        }

        return space;
    }

    function genSubconceptIndexes(uint32 dimId, uint32 start, uint32[] memory samplesIndexes) view public returns (uint32[] memory)
    {
        uint32[] memory subspace;
        uint32[] memory compositeIndexes = new uint32[](samplesIndexes.length);
        
        // need to generate subspace from 0 up to max(samplesIndexes) + 1
        uint32 subspaceSize = 0;
        for(uint32 i = 0; i < samplesIndexes.length; ++i)
        {
            if(samplesIndexes[i] > subspaceSize)subspaceSize = samplesIndexes[i];
        }
        subspaceSize += 1;

        // because we need to sample from this space element [max(samplesIndexes)]
        subspace = this.generateSubconceptSpace(dimId, start, subspaceSize);

        // sample composite subspace
        for(uint32 i = 0; i < compositeIndexes.length; ++i)
        {
            compositeIndexes[i] = subspace[samplesIndexes[i]];
        }

        return compositeIndexes;
    }
} 