// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../feature/IFeature.sol";
import "../transformation/ITransformation.sol";

interface IRunInstance
{
    function getStartPoint() external view returns (uint32);
    function getTransformationStartIndex() external view returns (uint32);
    function getTransformationEndIndex() external view returns (uint32);
}

interface IRegistry
{
    event Fallback(address caller,  string message);
    event FeatureAdded(address caller, string name, address featureAddr);
    event TransformationAdded(address caller, string name, address transformationAddr);
    event RunInstanceAdded(address caller, string featureName, string runInstanceName, address runInstanceAddr);

    event FeatureRemoved(address caller, string name);
    event TransformationRemoved(address caller, string name);
    event RunInstanceRemoved(address caller, string featureName, string runInstanceName);

    function registerFeature(string calldata name, IFeature feature) external;
    function registerTransformation(string calldata name, ITransformation transformation) external;
    function registerRunInstance(string calldata featureName, string calldata runInstanceName, IRunInstance runInstance) external;

    function getFeature(string calldata name) external view returns (IFeature);
    function getTransformation(string calldata name) external view returns (ITransformation);
    function getRunInstance(string calldata featureName, string calldata runInstanceName) external view returns (IRunInstance);

    function clearFeature(string calldata name) external;
    function clearTransformation(string calldata name) external;
    function clearRunInstance(string calldata featureName, string calldata runInstanceName) external;

    function containsFeature(string calldata name) external view returns (bool);
    function containsTransformation(string calldata name) external view returns (bool);
    function containsRunInstance(string calldata featureName, string calldata runInstanceName) external view returns (bool);

    function featuresCount() external view returns (uint);
    function transformationsCount() external view returns (uint);
    function runInstancesCount(string calldata featureName) external view returns (uint);
}