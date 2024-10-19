// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../Concept.sol";
import "../Registry.sol";

contract Duration is Concept
{
    string[] private composites;
    function (uint32) pure returns (uint32)[][] ops;

    constructor(address registryAddr) Concept(registryAddr, "Duration", composites, ops)
    {}
}