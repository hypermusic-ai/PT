// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../Operand.sol";

contract Add is Operand
{
    constructor(address registryAddr) Operand(registryAddr, "Add", 1)
    {}

    function run(uint32 x, uint32 [] calldata args) view external override returns (uint32)
    {
        require(args.length == this.getArgsCount(), "wrong number of arguments");
        return x + args[0];
    }
}