// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Concept.sol";

contract Registry
{
    mapping(string => address) private concepts;

    event Received(address caller,  string message);

    fallback() external {
        emit Received(msg.sender, "Fallback was called");
    }

    function register(string calldata name, Concept instance) external
    {
        require(this.contains(name) == false, string.concat(name, " concept of this name already registered"));
        concepts[name] = address(instance);
    }

    function at(string calldata name) external view returns (Concept)
    {
        return Concept(concepts[name]);
    }

    function clear(string calldata name) external
    {
        concepts[name] = address(0);
    }

    function contains(string calldata name) external view returns (bool)
    {
        return concepts[name] != address(0);
    }
}