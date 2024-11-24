// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../Operand.sol";

contract Nop is Operand 
{
    constructor(address registryAddr) Operand(registryAddr, "Nop", 0)
    {}

    function run(uint32 x, uint32 [] calldata args) view external override returns (uint32)
    {
        require(args.length == this.getArgsCount(), "wrong number of arguments");
        return x;
    }
}