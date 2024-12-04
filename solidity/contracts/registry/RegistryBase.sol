// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./IRegistry.sol";

contract RegistryBase is IRegistry
{
    mapping(string => address) private _concepts;
    mapping(string => address) private _transformations;

    uint256 private _conceptsCount;
    uint256 private _transformationsCount;

    // This function is executed on a call to the contract if none of the other
    // functions match the given function signature, or if no data is supplied at all
    fallback() external {
        emit Fallback(msg.sender, "Fallback was called");
    }

    function registerConcept(string calldata name, IConcept concept) external {
        require(!this.containsConcept(name), string.concat(name, " concept of this name already registered"));
        _concepts[name] = address(concept);
        _conceptsCount++;
        emit ConceptAdded(msg.sender, name, _concepts[name]);
    }

    function registerTransformation(string calldata name, ITransformation transformation) external {
        require(!this.containsTransformation(name), string.concat(name, " transformation of this name already registered"));
        _transformations[name] = address(transformation);
        _transformationsCount++;
        emit TransformationAdded(msg.sender, name, _transformations[name]);
    }

    function conceptAt(string calldata name) external view returns (IConcept)
    {
        assert(_concepts[name] != address(0));
        return IConcept(_concepts[name]);
    }

    function transformationAt(string calldata name) external view returns (ITransformation)
    {
        assert(_transformations[name] != address(0));
        return ITransformation(_transformations[name]);
    }

    function clearConcept(string calldata name) external {
        require(this.containsConcept(name), "Concept does not exist");
        _concepts[name] = address(0);
        _conceptsCount--;
        emit ConceptRemoved(msg.sender, name);
    }

    function clearTransformation(string calldata name) external {
        require(this.containsTransformation(name), "transformation does not exist");
        _transformations[name] = address(0);
        _transformationsCount--;
        emit TransformationRemoved(msg.sender, name);
    }

    function containsConcept(string calldata name) external view returns (bool)
    {
        return _concepts[name] != address(0);
    }

    function containsTransformation(string calldata name) external view returns (bool)
    {
        return _transformations[name] != address(0);
    }

    function conceptsCount() external view returns (uint) {
        return _conceptsCount;
    }

    function transformationsCount() external view returns (uint) {
        return _transformationsCount;
    }
}