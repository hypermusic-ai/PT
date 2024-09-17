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
        concepts[name] = address(instance);
    }

    function at(string calldata name) external view returns (address)
    {
        return concepts[name];
    }
}