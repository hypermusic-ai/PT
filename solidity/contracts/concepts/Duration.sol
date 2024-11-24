// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../Concept.sol";
import "../Registry.sol";

contract Duration is Concept
{
    string[]      private _composites;

    constructor(address registryAddr) Concept(registryAddr, "Duration", _composites)
    {}
}