// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "contracts/concept/ConceptBase.sol";

contract Time is ConceptBase
{
    string[]      private _composites;

    constructor(address registryAddr) ConceptBase(registryAddr, "Time", _composites)
    {}
}