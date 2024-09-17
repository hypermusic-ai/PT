// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../Concept.sol";
import "../Registry.sol";

contract Time is Concept
{
    uint8 constant D = 1;
    string[] private composites;
    function (uint32) pure returns (uint32)[][D] ops = [[next]];

    constructor(address registryAddr) Concept(registryAddr, "Time", composites)
    {
    }

    function transform(uint8 dimIdx, uint8 opIdx, uint32 x) override external view returns (uint32)
    {
        assert(dimIdx < D);
        return ops[dimIdx][opIdx](x);
    }
}