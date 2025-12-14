// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./IRegistry.sol";
import "../error/Error.sol";

contract RegistryBase is IRegistry
{
    mapping(string => address) private _features;
    mapping(string => address) private _transformations;
    mapping(string => address) private _conditions;

    uint256 private _featuresCount;
    uint256 private _transformationsCount;
    uint256 private _conditionsCount;

    // This function is executed on a call to the contract if none of the other
    // functions match the given function signature, or if no data is supplied at all
    fallback() external {
        revert RegistryError(1);
    }

    function registerFeature(string calldata name, IFeature feature) external {
        if(_features[name] != address(0))
        {
            revert FeatureAlreadyRegistered(keccak256(bytes(name)));
        }
        
        _features[name] = address(feature);
        _featuresCount++;
        emit FeatureAdded(msg.sender, name, _features[name]);
    }

    function registerTransformation(string calldata name, ITransformation transformation) external {
        if(_transformations[name] != address(0))
        {
            revert TransformationAlreadyRegistered(keccak256(bytes(name)));
        }
        
        _transformations[name] = address(transformation);
        _transformationsCount++;
        emit TransformationAdded(msg.sender, name, _transformations[name]);
    }

    function registerCondition(string calldata name, ICondition condition) external {
        if(_conditions[name] != address(0))
        {
            revert ConditionAlreadyRegistered(keccak256(bytes(name)));
        }
        
        _conditions[name] = address(condition);
        _conditionsCount++;
        emit ConditionAdded(msg.sender, name, _conditions[name]);
    }

    function getFeature(string calldata name) external view returns (IFeature)
    {
        if(_features[name] == address(0))
        {
            revert FeatureMissing(keccak256(bytes(name)));
        }
        return IFeature(_features[name]);
    }

    function getTransformation(string calldata name) external view returns (ITransformation)
    {
        if(_transformations[name] == address(0))
        {
            revert TransformationMissing(keccak256(bytes(name)));
        }
        return ITransformation(_transformations[name]);
    }

    function getCondition(string calldata name) external view returns (ICondition)
    {
        if(_conditions[name] == address(0))
        {
            revert ConditionMissing(keccak256(bytes(name)));
        }
        return ICondition(_conditions[name]);
    }

    function clearFeature(string calldata name) external {
        if(_features[name] == address(0))
        {
            revert FeatureMissing(keccak256(bytes(name)));
        }
        _features[name] = address(0);
        _featuresCount--;
        emit FeatureRemoved(msg.sender, name);
    }

    function clearTransformation(string calldata name) external {
        if(_transformations[name] == address(0))
        {
            revert TransformationMissing(keccak256(bytes(name)));
        }
        _transformations[name] = address(0);
        _transformationsCount--;
        emit TransformationRemoved(msg.sender, name);
    }

    function clearCondition(string calldata name) external {
        if(_conditions[name] == address(0))
        {
            revert ConditionMissing(keccak256(bytes(name)));
        }
        _conditions[name] = address(0);
        _conditionsCount--;
        emit ConditionRemoved(msg.sender, name);
    }

    function containsFeature(string calldata name) external view returns (bool)
    {
        return _features[name] != address(0);
    }

    function containsTransformation(string calldata name) external view returns (bool)
    {
        return _transformations[name] != address(0);
    }

    function containsCondition(string calldata name) external view returns (bool)
    {
        return _conditions[name] != address(0);
    }

    function featuresCount() external view returns (uint) {
        return _featuresCount;
    }

    function transformationsCount() external view returns (uint) {
        return _transformationsCount;
    }

    function conditionsCount() external view returns (uint) {
        return _conditionsCount;
    }
}