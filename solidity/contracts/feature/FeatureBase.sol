// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "./IFeature.sol";

import "../registry/IRegistry.sol";
import "../transformation/ITransformation.sol";
import "../condition/ICondition.sol";

import "../ownable/OwnableBase.sol";
import "../error/Error.sol";


abstract contract FeatureBase is IFeature, OwnableBase
{
    IRegistry               private _registry;
    IFeature[]              private _composites;
    string                  private _name;
    uint32                  private _scalars;
    uint32                  private _treeSize;
    ITransformation[][]     private _transformations;
    CallDef                 private _transformationsCallDef;
    ICondition              private _condition;
    int32[]                 private _conditionCheckArgs;
        
    //
    constructor(address registryAddr, string memory name, string[] memory compsNames, string memory conditionName, int32[] memory conditionCheckArgs)
    {
        assert(registryAddr != address(0));
        _registry = IRegistry(registryAddr);
        
        // find sub features
        for(uint32 i = 0; i < compsNames.length; ++i)
        {
            if(_registry.containsFeature(compsNames[i]) == false)
            {
                revert FeatureMissing(keccak256(bytes(compsNames[i])));
            }

            _composites.push(_registry.getFeature(compsNames[i]));
        }

        // allocate transformations memory
        _transformationsCallDef = new CallDef(_composites.length);
        _treeSize = 1;

        // calculate scalars
        if(_composites.length == 0)
        {
            // scalar type
            _scalars = 1;
        }
        else 
        {
            _transformations = new ITransformation[][](_composites.length);

            // composite type
            _scalars = 0;

            for(uint32 i = 0; i < _composites.length; ++i)
            {
                _scalars += _composites[i].getScalarsCount();
                _treeSize += _composites[i].getTreeSize();
            }
        }
        assert(_scalars > 0);

        // require condition
        if(bytes(conditionName).length != 0)
        {
            if(_registry.containsCondition(conditionName) == false)
            {
                revert ConditionMissing(keccak256(bytes(conditionName)));
            }

            // set condition
            _condition = _registry.getCondition(conditionName);

            if(conditionCheckArgs.length != _condition.getArgsCount())
            {
                revert ConditionArgumentsMismatch(keccak256(bytes(conditionName)));
            }
            // set args
            _conditionCheckArgs = conditionCheckArgs;
        }

        // set name
        _name = name;
    }

    function getCallDef() internal view returns (CallDef)
    {
        return _transformationsCallDef;
    }

    function init() internal
    {
        require(_transformationsCallDef.getDimensionsCount() == _transformations.length);

        for(uint8 dimId = 0; dimId < _transformations.length; ++dimId)
        {
            uint32 opCount = _transformationsCallDef.getTransformationsCount(dimId);

            for(uint8 opId = 0; opId < opCount; ++opId)
            {
                if(_registry.containsTransformation(_transformationsCallDef.names(dimId, opId)) == false)
                {
                    revert TransformationMissing(keccak256(bytes(_transformationsCallDef.names(dimId, opId))));
                }

                ITransformation transformation = _registry.getTransformation(_transformationsCallDef.names(dimId, opId));

                if(_transformationsCallDef.getArgsCount(dimId, opId) != transformation.getArgsCount())
                {
                    revert TransformationArgumentsMismatch(keccak256(bytes(_transformationsCallDef.names(dimId, opId))));
                }

                _transformations[dimId].push(transformation);
            }
        }

        // register
        _registry.registerFeature(_name, this);
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
    function getTreeSize() external view returns (uint32)
    {
        return _treeSize;
    }

    //
    function getCompositesCount() external view returns (uint32)
    {
        return (uint32)(_composites.length);
    }

    //
    function getComposite(uint32 id) external view returns (IFeature)
    {
        require(id < _composites.length, "composite id out of range");
        return _composites[id];
    }

    //
    function transform(uint32 dimId, uint32 opId, uint32 x) external view returns (uint32)
    {
        require(dimId < _transformations.length, "invalid dimension id");
        // no transformation for this dimension
        if(_transformations[dimId].length == 0)return x;
        
        opId %= (uint32)(_transformations[dimId].length);
        uint32 out = _transformations[dimId][opId].run(x, _transformationsCallDef.getArgs(dimId, opId));
        return out;
    }

    function checkCondition() external view override returns(bool)
    {
        // no condition
        if(address(_condition) == address(0)) return true;

        return _condition.check(_conditionCheckArgs);
    }
} 