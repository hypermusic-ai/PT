// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../feature/IFeature.sol";
import "../transformation/ITransformation.sol";

interface IRegistry
{
    event Fallback(address caller,  string message);
    event FeatureAdded(address caller, string name, address featureAddr);
    event TransformationAdded(address caller, string name, address transformationAddr);
    event FeatureRemoved(address caller, string name);
    event TransformationRemoved(address caller, string name);

    function registerFeature(string calldata name, IFeature feature) external;
    function registerTransformation(string calldata name, ITransformation transformation) external;

    function featureAt(string calldata name) external view returns (IFeature);
    function transformationAt(string calldata name) external view returns (ITransformation);

    function clearFeature(string calldata name) external;
    function clearTransformation(string calldata name) external;

    function containsFeature(string calldata name) external view returns (bool);
    function containsTransformation(string calldata name) external view returns (bool);

    function featuresCount() external view returns (uint);
    function transformationsCount() external view returns (uint);
}