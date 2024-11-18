// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Concept.sol";

contract Registry
{
    mapping(string => address) private concepts;
    uint private conceptCount; // Counter for the number of concepts

    event Received(address caller,  string message);
    event ConceptAdded(address caller, address conceptAddr, string name);
    event ConceptRemoved(address caller, string name);

    // This function is executed on a call to the contract if none of the other
    // functions match the given function signature, or if no data is supplied at all
    fallback() external {
        emit Received(msg.sender, "Fallback was called");
    }

    function register(string calldata name, Concept instance) external {
        require(!this.contains(name), string.concat(name, " concept of this name already registered"));
        concepts[name] = address(instance);
        conceptCount++; // Increment the counter
        emit ConceptAdded(msg.sender, concepts[name], name);
    }

    function at(string calldata name) external view returns (Concept)
    {
        return Concept(concepts[name]);
    }

    function clear(string calldata name) external {
        require(this.contains(name), "Concept does not exist");
        concepts[name] = address(0);
        conceptCount--; // Decrement the counter
        emit ConceptRemoved(msg.sender, name);
    }

    function contains(string calldata name) external view returns (bool)
    {
        return concepts[name] != address(0);
    }

    function length() external view returns (uint) {
        return conceptCount;
    }
}