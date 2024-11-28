// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "contracts/ownable/IOwnable.sol";
import "contracts/registry/IRegistry.sol";

interface IOperand is IOwnable
{
    function getArgsCount() external view returns(uint32);
    function run(uint32 x, uint32[] calldata args) external view returns (uint32);
}

contract CallDef
{
    constructor(uint256 dims)
    {
        names = new string[][](dims);
        args = new uint32[][][](dims);
    }

    function getDimensionsCount() external view returns(uint32)
    {
        assert(names.length == args.length);
        return uint32(names.length);
    }

    function getOperandsCount(uint32 dimId) external view returns(uint32)
    {
        require(dimId < this.getDimensionsCount());
        return uint32(names[dimId].length);
    }

    function getArgsCount(uint32 dimId, uint32 opId) external view returns(uint32)
    {
        require(dimId < this.getDimensionsCount());
        require(opId < this.getOperandsCount(dimId));
        return uint32(args[dimId][opId].length);
    }

    function getArgs(uint32 dimId, uint32 opId) external view returns(uint32[] memory)
    {
        require(dimId < this.getDimensionsCount());
        require(opId < this.getOperandsCount(dimId));
        return args[dimId][opId];
    }

    function allocate(uint32 dimId, uint32 opCount) external
    {
        require(dimId < names.length && dimId < args.length);
        names[dimId] = new string[](opCount);
        args[dimId] = new uint32[][](opCount);
    }

    function set0(uint32 dimId, uint32 opId, string calldata opName) external
    {
        require(dimId < names.length);
        require(opId < names[dimId].length);

        names[dimId][opId] = opName;
    }

    function set1(uint32 dimId, uint32 opId, string calldata opName, uint32[1] calldata argsArr) external
    {
        require(dimId < names.length && dimId < args.length);
        require(opId < names[dimId].length && opId < args[dimId].length);

        names[dimId][opId] = opName;
        args[dimId][opId] = argsArr;
    }

    function set2(uint32 dimId, uint32 opId, string calldata opName, uint32[2] calldata argsArr) external
    {
        require(dimId < names.length && dimId < args.length);
        require(opId < names[dimId].length && opId < args[dimId].length);

        names[dimId][opId] = opName;
        args[dimId][opId] = argsArr;
    }

    function set2(uint32 dimId, uint32 opId, string calldata opName, uint32[3] calldata argsArr) external
    {
        require(dimId < names.length && dimId < args.length);
        require(opId < names[dimId].length && opId < args[dimId].length);

        names[dimId][opId] = opName;
        args[dimId][opId] = argsArr;
    }

    // ----------------

    function push0(uint32 dimId, string calldata opName) external
    {
        require(dimId < names.length);
        names[dimId].push(opName);
        args[dimId].push();
    }

    function push1(uint32 dimId, string calldata opName, uint32[1] calldata argsArr) external
    {
        require(dimId < names.length && dimId < args.length);

        names[dimId].push(opName);
        args[dimId].push(argsArr);
    }

    function push2(uint32 dimId, string calldata opName, uint32[2] calldata argsArr) external
    {
        require(dimId < names.length && dimId < args.length);

        names[dimId].push(opName);
        args[dimId].push(argsArr);
    }

    function push3(uint32 dimId, string calldata opName, uint32[3] calldata argsArr) external
    {
        require(dimId < names.length && dimId < args.length);

        names[dimId].push(opName);
        args[dimId].push(argsArr);
    }

    string[][] public names;
    uint32[][][] public args;
}