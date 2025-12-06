// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./IRegistry.sol";
import "../error/Error.sol";

contract RegistryBase is IRegistry
{
    mapping(string => address) private _features;
    mapping(string => address) private _transformations;
    mapping(string => mapping(string => address)) private _runInstances;

    uint256 private _featuresCount;
    uint256 private _transformationsCount;
    mapping(string => uint256) private _runInstancesCount;

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

    function registerRunInstance(string calldata featureName, string calldata runInstanceName, IRunInstance runInstance) external
    {
        if(_runInstances[featureName][runInstanceName] != address(0))
        {
            revert RunInstanceAlreadyRegistered(keccak256(bytes(featureName)), keccak256(bytes(runInstanceName)));
        }
        
        _runInstances[featureName][runInstanceName] = address(runInstance);
        _runInstancesCount[featureName]++;
        emit RunInstanceAdded(msg.sender, featureName, runInstanceName, _runInstances[featureName][runInstanceName]);
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

    function getRunInstance(string calldata featureName, string calldata runInstanceName) external view returns (IRunInstance)
    {
        if(_runInstances[featureName][runInstanceName] == address(0))
        {
            revert RunInstanceMissing(keccak256(bytes(featureName)), keccak256(bytes(runInstanceName)));
        }
        return IRunInstance(_runInstances[featureName][runInstanceName]);
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

    function clearRunInstance(string calldata featureName, string calldata runInstanceName) external {
        if(_runInstances[featureName][runInstanceName] == address(0))
        {
            revert RunInstanceMissing(keccak256(bytes(featureName)), keccak256(bytes(runInstanceName)));
        }

        _runInstances[featureName][runInstanceName] = address(0);
        _runInstancesCount[featureName]--;
        emit RunInstanceRemoved(msg.sender, featureName, runInstanceName);
    }

    function containsFeature(string calldata name) external view returns (bool)
    {
        return _features[name] != address(0);
    }

    function containsTransformation(string calldata name) external view returns (bool)
    {
        return _transformations[name] != address(0);
    }

    function containsRunInstance(string calldata featureName, string calldata runInstanceName) external view returns (bool)
    {
        return _runInstances[featureName][runInstanceName] != address(0);
    }

    function featuresCount() external view returns (uint) {
        return _featuresCount;
    }

    function transformationsCount() external view returns (uint) {
        return _transformationsCount;
    }

    function runInstancesCount(string calldata featureName) external view returns (uint) {
        return _runInstancesCount[featureName];
    }
}