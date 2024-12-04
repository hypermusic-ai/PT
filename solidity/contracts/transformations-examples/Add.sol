// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../transformation/TransformationBase.sol";

contract Add is TransformationBase
{
    constructor(address registryAddr) TransformationBase(registryAddr, "Add", 1)
    {}

    function run(uint32 x, uint32 [] calldata args) view external returns (uint32)
    {
        require(args.length == this.getArgsCount(), "wrong number of arguments");
        return x + args[0];
    }
}