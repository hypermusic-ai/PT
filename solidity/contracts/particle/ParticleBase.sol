// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "./IParticle.sol";

import "../registry/IRegistry.sol";
import "../feature/IFeature.sol";
import "../transformation/ITransformation.sol";
import "../condition/ICondition.sol";

import "../ownable/OwnableBase.sol";
import "../error/Error.sol";


abstract contract ParticleBase is IParticle, OwnableBase
{
    IRegistry               private _registry;
    string                  private _name;

    IFeature                private _feature;
    address[]               private _composites;

    uint32                  private _scalars;

    ICondition              private _condition;
    int32[]                 private _conditionCheckArgs;
        
    //
    function __ParticleBase_init(address registryAddr, string memory name,
        string memory featureName, string[] memory compsNames,
        string memory conditionName, int32[] memory conditionCheckArgs) internal onlyInitializing {
        assert(registryAddr != address(0));
        __OwnableBase_init(msg.sender);

        _registry = IRegistry(registryAddr);
        
        // find assigned feature
        if (_registry.containsFeature(featureName) == false)
        {
            revert FeatureMissing(keccak256(bytes(featureName)));
        }

        _feature = _registry.getFeature(featureName);

        // we need to have the same number of dimensions as our feature
        if(_feature.getDimensionsCount() != compsNames.length)
        {
            revert ParticleDimensionsMismatch(keccak256(bytes(name)));
        }

        // allocate memory for composites
        _composites = new address[](_feature.getDimensionsCount());

        _scalars = 0;

        // find sub particles
        for(uint32 i = 0; i < compsNames.length; ++i)
        {
            if (bytes(compsNames[i]).length == 0)
            {
                // this will be the scalar path
                _composites[i] = address(0);
                _scalars += 1;
            }
            else 
            { 
                // this will be the composite path
                if(_registry.containsParticle(compsNames[i]) == false)
                {
                    revert ParticleMissing(keccak256(bytes(compsNames[i])));
                }

                IParticle composite = _registry.getParticle(compsNames[i]);

                _scalars += composite.getScalarsCount();

                _composites[i] = address(composite);
            }
        }

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

        // register particle
        _registry.registerParticle(_name, this);
    }

    //
    function getName() external view returns(string memory)
    {
        return _name;
    }

    //
    function getScalarsCount() external view returns (uint32)
    {
        return _scalars;
    }

    //
    function getRootFeature() external view returns (IFeature)
    {
        return _feature;
    }

    //
    function getCompositesCount() external view returns (uint32)
    {
        return (uint32)(_composites.length);
    }

    //
    function getComposite(uint32 dimId) external view returns (address)
    {
        require(dimId < _composites.length, "composite dimension Id out of range");
        return _composites[dimId];
    }

    function checkCondition() external view override returns(bool)
    {
        // no condition
        if(address(_condition) == address(0)) return true;

        return _condition.check(_conditionCheckArgs);
    }
} 
