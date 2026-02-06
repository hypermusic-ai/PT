// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "../feature/IFeature.sol";
import "../transformation/ITransformation.sol";
import "../condition/ICondition.sol";
import "../particle/IParticle.sol";

interface IRegistry
{
    event FeatureAdded(address caller, string name, address featureAddr);
    event TransformationAdded(address caller, string name, address transformationAddr);
    event ConditionAdded(address caller, string name, address conditionAddr);
    event ParticleAdded(address caller, string name, address particleAddr);

    event FeatureRemoved(address caller, string name);
    event TransformationRemoved(address caller, string name);
    event ConditionRemoved(address caller, string name);
    event ParticleRemoved(address caller, string name);

    function registerFeature(string calldata name, IFeature feature) external;
    function registerTransformation(string calldata name, ITransformation transformation) external;
    function registerCondition(string calldata name, ICondition condition) external;
    function registerParticle(string calldata name, IParticle particle) external;

    function getFeature(string calldata name) external view returns (IFeature);
    function getTransformation(string calldata name) external view returns (ITransformation);
    function getCondition(string calldata name) external view returns (ICondition);
    function getParticle(string calldata name) external view returns (IParticle);

    function clearFeature(string calldata name) external;
    function clearTransformation(string calldata name) external;
    function clearCondition(string calldata name) external;
    function clearParticle(string calldata name) external;

    function containsFeature(string calldata name) external view returns (bool);
    function containsTransformation(string calldata name) external view returns (bool);
    function containsCondition(string calldata name) external view returns (bool);
    function containsParticle(string calldata name) external view returns (bool);

    function featuresCount() external view returns (uint);
    function transformationsCount() external view returns (uint);
    function conditionsCount() external view returns (uint);
    function particlesCount() external view returns (uint);
}