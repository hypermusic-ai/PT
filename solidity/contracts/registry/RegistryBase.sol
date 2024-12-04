// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./IRegistry.sol";

contract RegistryBase is IRegistry
{
    mapping(string => address) private _features;
    mapping(string => address) private _transformations;

    uint256 private _featuresCount;
    uint256 private _transformationsCount;

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

    function featureAt(string calldata name) external view returns (IFeature)
    {
        assert(_features[name] != address(0));
        return IFeature(_features[name]);
    }

    function transformationAt(string calldata name) external view returns (ITransformation)
    {
        assert(_transformations[name] != address(0));
        return ITransformation(_transformations[name]);
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

    function containsFeature(string calldata name) external view returns (bool)
    {
        return _features[name] != address(0);
    }

    function containsTransformation(string calldata name) external view returns (bool)
    {
        return _transformations[name] != address(0);
    }

    function featuresCount() external view returns (uint) {
        return _featuresCount;
    }

    function transformationsCount() external view returns (uint) {
        return _transformationsCount;
    }
}