// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./IFeature.sol";

import "../registry/IRegistry.sol";
import "../condition/ICondition.sol";
import "../transformation/ITransformation.sol";

import "../ownable/OwnableBase.sol";

event Debug(string label, string value);

abstract contract FeatureBase is IFeature, OwnableBase
{
    IRegistry               private _registry;
    ICondition              private _condition;
    IFeature[]              private _composites;
    string                  private _name;
    uint32                  private _scalars;
    uint32                  private _subTreeSize;
    ITransformation[][]     private _transformations;
    CallDef                 private _transformationsCallDef;
        
    //
    constructor(address registryAddr, ICondition condition, string memory name, string[] storage compsNames)
    {
        assert(registryAddr != address(0));
        _registry = IRegistry(registryAddr);
        _condition = condition;
        
        emit Debug("FeatureBase compsNames.length", Strings.toString(compsNames.length));

        // find subfeatures
        for(uint32 i = 0; i < compsNames.length; ++i)
        {
            require(_registry.containsFeature(compsNames[i]), string.concat("cannot find composite feature: ", compsNames[i]));
            _composites.push(_registry.getFeature(compsNames[i]));
        }

        // allocate transformations memory
        _transformationsCallDef = new CallDef(_composites.length);

        // calculate scalars
        if(_composites.length == 0)
        {
            // scalar type
            _scalars = 1;
            _subTreeSize = 0;
        }
        else 
        {
            _transformations = new ITransformation[][](_composites.length);

            // composite type
            _scalars = 0;
            _subTreeSize = (uint32)(_composites.length);

            for(uint32 i = 0; i < _composites.length; ++i)
            {
                _scalars += _composites[i].getScalarsCount();
                _subTreeSize += _composites[i].getSubTreeSize();
            }
        }
        assert(_scalars > 0);

        // set name
        _name = name;

        // register
        _registry.registerFeature(_name, this);
    }

    function getCallDef() internal view returns (CallDef)
    {
        return _transformationsCallDef;
    }

    function initTransformations() internal
    {
        require(_transformationsCallDef.getDimensionsCount() == _transformations.length);

        for(uint8 dimId = 0; dimId < _transformations.length; ++dimId)
        {
            uint32 opCount = _transformationsCallDef.getTransformationsCount(dimId);

            for(uint8 opId = 0; opId < opCount; ++opId)
            {
                require(_registry.containsTransformation(_transformationsCallDef.names(dimId, opId)), 
                    string.concat("cannot find transformation : ", _transformationsCallDef.names(dimId, opId)));

                _transformations[dimId].push(_registry.getTransformation(_transformationsCallDef.names(dimId, opId)));
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
        uint32 out = _transformations[dimId][opId].run(x, getCallDef().getArgs(dimId, opId));
        return out;
    }

    function checkCondition() external view override returns(bool)
    {
        return _condition.check();
    }

    function updateCondition() external override
    {
        return _condition.update();
    }
} 