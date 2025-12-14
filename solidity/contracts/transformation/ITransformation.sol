// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "../ownable/IOwnable.sol";

interface ITransformation is IOwnable
{
    /// @notice Get number of arguments for transformation
    function getArgsCount() external view returns(uint32);

    /// @notice Run an operator.
    ///
    /// @param x The index value to be processed.
    /// @param args Array containing arguments for this operator.
    function run(uint32 x, uint32[] calldata args) external view returns (uint32);
}

contract CallDef
{
    string[][] public names;
    uint32[][][] public args;

    constructor(uint256 dims)
    {
        names = new string[][](dims);
        args = new uint32[][][](dims);
    }

    function getDimensionsCount() external view returns(uint32)
    {
        return uint32(names.length);
    }

    function getTransformationsCount(uint32 dimId) external view returns(uint32)
    {
        require(dimId < names.length, "invalid dimension id");
        return uint32(names[dimId].length);
    }

    function getArgsCount(uint32 dimId, uint32 opId) external view returns(uint32)
    {
        require(dimId < names.length, "invalid dimension id");
        require(opId < names[dimId].length, "invalid operation id");
        return uint32(args[dimId][opId].length);
    }

    /// @notice Get arguments of transformation at index opId in dimension dimId.
    ///
    /// @dev This operation returns args array associated with name at
    /// index opId and dimension dimId.
    function getArgs(uint32 dimId, uint32 opId) external view returns(uint32[] memory)
    {
        require(dimId < names.length, "invalid dimension id");
        require(opId < names[dimId].length, "invalid operation id");
        return args[dimId][opId];
    }

    /// @notice Push a definition of operator with dynamically allocated argument list.
    ///
    /// @param dimId The index of dimensions array where new transformation should be stored.
    /// @param opName Name for the newly pushed operator.
    /// @param argsArr Array containing arguments for this operator.
    function push(uint32 dimId, string calldata opName, uint32[] memory argsArr) external
    {
        require(dimId < names.length, "invalid dimension id");
        names[dimId].push(opName);
        args[dimId].push(argsArr);
    }

    /// @notice Push a definition of operator with does not tak any arguments.
    ///
    /// @param dimId The index of dimensions array where new transformation should be stored.
    /// @param opName Name for the newly pushed operator.
    function push(uint32 dimId, string calldata opName) external
    {
        require(dimId < names.length, "invalid dimension id");
        names[dimId].push(opName);
        args[dimId].push();
    }

    /// @notice Push a definition of operator with statically allocated argument list of size 1.
    ///
    /// @param dimId The index of dimensions array where new transformation should be stored.
    /// @param opName Name for the newly pushed operator.
    /// @param argsArr Array containing arguments for this operator.
    function push(uint32 dimId, string calldata opName, uint32[1] calldata argsArr) external
    {
        require(dimId < names.length && dimId < args.length, "invalid dimension id");

        names[dimId].push(opName);
        args[dimId].push(argsArr);
    }

    /// @notice Push a definition of operator with statically allocated argument list of size 2.
    ///
    /// @param dimId The index of dimensions array where new transformation should be stored.
    /// @param opName Name for the newly pushed operator.
    /// @param argsArr Array containing arguments for this operator.
    function push(uint32 dimId, string calldata opName, uint32[2] calldata argsArr) external
    {
        require(dimId < names.length && dimId < args.length, "invalid dimension id");

        names[dimId].push(opName);
        args[dimId].push(argsArr);
    }

    /// @notice Push a definition of operator with statically allocated argument list of size 3.
    ///
    /// @param dimId The index of dimensions array where new transformation should be stored.
    /// @param opName Name for the newly pushed operator.
    /// @param argsArr Array containing arguments for this operator.
    function push(uint32 dimId, string calldata opName, uint32[3] calldata argsArr) external
    {
        require(dimId < names.length && dimId < args.length, "invalid dimension id");

        names[dimId].push(opName);
        args[dimId].push(argsArr);
    }

    /// @notice Push a definition of operator with statically allocated argument list of size 4.
    ///
    /// @param dimId The index of dimensions array where new transformation should be stored.
    /// @param opName Name for the newly pushed operator.
    /// @param argsArr Array containing arguments for this operator.
    function push(uint32 dimId, string calldata opName, uint32[4] calldata argsArr) external
    {
        require(dimId < names.length && dimId < args.length, "invalid dimension id");

        names[dimId].push(opName);
        args[dimId].push(argsArr);
    }

    /// @notice Push a definition of operator with statically allocated argument list of size 5.
    ///
    /// @param dimId The index of dimensions array where new transformation should be stored.
    /// @param opName Name for the newly pushed operator.
    /// @param argsArr Array containing arguments for this operator.
    function push(uint32 dimId, string calldata opName, uint32[5] calldata argsArr) external
    {
        require(dimId < names.length && dimId < args.length, "invalid dimension id");

        names[dimId].push(opName);
        args[dimId].push(argsArr);
    }
}