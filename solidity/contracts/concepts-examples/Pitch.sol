// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../concept/ConceptBase.sol";

contract Pitch is ConceptBase
{
    string[]      private _composites;

    constructor(address registryAddr) ConceptBase(registryAddr, "Pitch", _composites)
    {}
}