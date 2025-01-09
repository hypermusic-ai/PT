// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./IRegistry.sol";

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
        emit Fallback(msg.sender, "Fallback was called");
    }

    function registerFeature(string calldata name, IFeature feature) external {
        require(!this.containsFeature(name), string.concat(name, " feature of this name already registered"));
        _features[name] = address(feature);
        _featuresCount++;
        emit FeatureAdded(msg.sender, name, _features[name]);
    }

    function registerTransformation(string calldata name, ITransformation transformation) external {
        require(!this.containsTransformation(name), string.concat(name, " transformation of this name already registered"));
        _transformations[name] = address(transformation);
        _transformationsCount++;
        emit TransformationAdded(msg.sender, name, _transformations[name]);
    }

    function registerRunInstance(string calldata featureName, string calldata runInstanceName, IRunInstance runInstance) external
    {
        require(!this.containsRunInstance(featureName, runInstanceName), string.concat(featureName, ":", runInstanceName, " RunInstance already registered"));
        _runInstances[featureName][runInstanceName] = address(runInstance);
        _runInstancesCount[featureName]++;
        emit RunInstanceAdded(msg.sender, featureName, runInstanceName, _runInstances[featureName][runInstanceName]);
    }

    function getFeature(string calldata name) external view returns (IFeature)
    {
        assert(_features[name] != address(0));
        return IFeature(_features[name]);
    }

    function getTransformation(string calldata name) external view returns (ITransformation)
    {
        assert(_transformations[name] != address(0));
        return ITransformation(_transformations[name]);
    }

    function getRunInstance(string calldata featureName, string calldata runInstanceName) external view returns (IRunInstance)
    {
        assert(_runInstances[featureName][runInstanceName] != address(0));
        return IRunInstance(_runInstances[featureName][runInstanceName]);
    }

    function clearFeature(string calldata name) external {
        require(this.containsFeature(name), "feature does not exist");
        _features[name] = address(0);
        _featuresCount--;
        emit FeatureRemoved(msg.sender, name);
    }

    function clearTransformation(string calldata name) external {
        require(this.containsTransformation(name), "transformation does not exist");
        _transformations[name] = address(0);
        _transformationsCount--;
        emit TransformationRemoved(msg.sender, name);
    }

    function clearRunInstance(string calldata featureName, string calldata runInstanceName) external {
        require(this.containsRunInstance(featureName, runInstanceName), "Run Instance does not exist");
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