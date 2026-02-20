// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "./IFeature.sol";

import "../registry/IRegistry.sol";
import "../transformation/ITransformation.sol";

import "../ownable/OwnableBase.sol";
import "../error/Error.sol";


abstract contract FeatureBase is IFeature, OwnableBase
{
    IRegistry               private _registry;
    string                  private _name;
    ITransformation[][]     private _transformations;
    CallDef                 private _transformationsCallDef;

    function __FeatureBase_init(address registryAddr, string memory name, uint32 dimensionsCount) internal onlyInitializing {
        assert(registryAddr != address(0));
        assert(dimensionsCount > 0);
        __OwnableBase_init(msg.sender);

        _registry = IRegistry(registryAddr);

        if(_registry.containsFeature(name))
        {
            revert FeatureAlreadyRegistered(keccak256(bytes(name)));
        }

        _transformationsCallDef = new CallDef(dimensionsCount);
        _transformations = new ITransformation[][](dimensionsCount);

        // set name
        _name = name;
    }

    function getCallDef() internal view returns (CallDef)
    {
        return _transformationsCallDef;
    }

    function __FeatureBase_finalizeInit() internal onlyInitializing
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

    function init() internal onlyInitializing
    {
        __FeatureBase_finalizeInit();
    }

    //
    function getName() external view returns(string memory)
    {
        return _name;
    }

    //
    function getDimensionsCount() external view returns (uint32)
    {
        return (uint32)(_transformations.length);
    }

    //
    function transform(uint32 dimId, uint32 txId, uint32 x) external view returns (uint32)
    {
        require(dimId < _transformations.length, "invalid dimension id");
        // no transformation for this dimension
        if(_transformations[dimId].length == 0)return x;
        
        txId %= (uint32)(_transformations[dimId].length);
        uint32 out = _transformations[dimId][txId].run(x, _transformationsCallDef.getArgs(dimId, txId));
        return out;
    }
} 
