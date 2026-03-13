// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "./IConnector.sol";

import "../registry/IRegistry.sol";
import "../feature/IFeature.sol";
import "../transformation/ITransformation.sol";
import "../condition/ICondition.sol";

import "../ownable/OwnableBase.sol";
import "../error/Error.sol";


abstract contract ConnectorBase is IConnector, OwnableBase
{
    IRegistry               private _registry;
    string                  private _name;

    IFeature                private _feature;
    IConnector[]             private _composites;

    uint32                  private _scalars;

    ICondition              private _condition;
    int32[]                 private _conditionCheckArgs;
        
    //
    function __ConnectorBase_init(address registryAddr, string memory name,
        string memory featureName, uint32[] memory compositeDimIds, string[] memory compositeNames,
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

        if(compositeDimIds.length != compositeNames.length)
        {
            revert ConnectorDimensionsMismatch(keccak256(bytes(name)));
        }

        uint32 dimensionsCount = _feature.getDimensionsCount();

        // allocate memory for composites
        _composites = new IConnector[](dimensionsCount);

        _scalars = dimensionsCount;

        // find sub connectors
        for(uint32 i = 0; i < compositeNames.length; ++i)
        {
            uint32 dimId = compositeDimIds[i];
            if(dimId >= dimensionsCount)
            {
                revert ConnectorDimensionsMismatch(keccak256(bytes(name)));
            }

            if(address(_composites[dimId]) != address(0))
            {
                revert ConnectorDimensionsMismatch(keccak256(bytes(name)));
            }

            if(bytes(compositeNames[i]).length == 0)
            {
                revert ConnectorDimensionsMismatch(keccak256(bytes(name)));
            }

            // this will be the composite path
            if(_registry.containsConnector(compositeNames[i]) == false)
            {
                revert ConnectorMissing(keccak256(bytes(compositeNames[i])));
            }

            IConnector composite = _registry.getConnector(compositeNames[i]);
            _composites[dimId] = composite;

            _scalars += composite.getScalarsCount();
            assert(_scalars > 0);
            _scalars -= 1;
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

        IRegistry.ConnectorRegistration memory registration = IRegistry.ConnectorRegistration({
            owner: msg.sender,
            featureName: featureName,
            compositeDimIds: compositeDimIds,
            compositeNames: compositeNames,
            conditionName: conditionName,
            conditionArgs: conditionCheckArgs
        });

        // register connector
        _registry.registerConnector(
            _name,
            this,
            registration
        );
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
    function getComposite(uint32 dimId) external view returns (IConnector)
    {
        require(dimId < _composites.length, "composite dimension Id out of range");
        return _composites[dimId];
    }

    function getCondition() external view returns (ICondition)
    {
        return _condition;
    }

    function getConditionArgs() external view returns (int32[] memory)
    {
        return _conditionCheckArgs;
    }

    function checkCondition() external view override returns(bool)
    {
        // no condition
        if(address(_condition) == address(0)) return true;

        return _condition.check(_conditionCheckArgs);
    }
} 