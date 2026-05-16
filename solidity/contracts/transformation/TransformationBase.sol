// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./ITransformation.sol";
import "../registry/IRegistry.sol";
import "../ownable/OwnableConstructorBase.sol";

/// @dev Future optimization (not yet implemented):
///
/// For transformations whose author knows them to be linear or affine
/// (e.g. `return x + K;` for constant K, or more generally
/// `return a * x + b;` with constants), an *opt-in* override of
/// `runAt` / `runRange` can compute the sampled space in O(K) where
/// K = output length, instead of the default O(maxOffset). The base
/// class deliberately does **not** infer linearity from `sol_src` —
/// transformations may be arbitrary EVM code with control flow and
/// side effects — so the speedup must be authored explicitly.
///
/// To opt in, override `runAt` (and optionally `runRange`) in the
/// concrete contract and emit values directly. The on-chain `Runner`
/// always dispatches through the public ABI, so this override is
/// picked up automatically.
abstract contract TransformationBase is ITransformation, OwnableConstructorBase
{
    IRegistry    private _registry;
    string      private _name;
    uint32      internal _argc;

    constructor(address registryAddr, string memory name, uint32 argc)
        OwnableConstructorBase(msg.sender)
    {
        require(registryAddr != address(0), "registry is zero");

        _registry = IRegistry(registryAddr);
        _name = name;
        _argc = argc;

        IRegistry.TransformationRegistration memory registration = IRegistry.TransformationRegistration({
            owner: msg.sender,
            argsCount: _argc
        });

        _registry.registerTransformation(_name, this, registration);
    }

    function getArgsCount() external view returns(uint32)
    {
        return _argc;
    }

    /// @dev Concrete transformation body. Generated contracts override
    /// this with the user-supplied `sol_src` expression. Internal so
    /// the loops in run/runRange/runAt do not pay per-step CALL costs.
    function _runImpl(uint32 x, uint32[] memory args) internal view virtual returns (uint32);

    function run(uint32 x, uint32[] calldata args) external view virtual returns (uint32)
    {
        require(args.length == _argc, "wrong number of arguments");
        return _runImpl(x, args);
    }

    /// @dev Contiguous iterative evaluation: returns
    ///      [startX, run(startX), run(run(startX)), ...] of length count.
    /// All iterations happen inside this single CALL frame and dispatch
    /// to the internal `_runImpl`, so no per-step external CALL is paid.
    /// Counter arithmetic is `unchecked` because `i` is bounded above by
    /// the caller-supplied `count` (uint32) and cannot wrap.
    function runRange(uint32 startX, uint32 /*startOp*/, uint32 count, uint32[] calldata args)
        external view virtual returns (uint32[] memory)
    {
        require(args.length == _argc, "wrong number of arguments");

        uint32[] memory space = new uint32[](count);
        if(count == 0)
        {
            return space;
        }

        uint32[] memory argsMem = args;
        uint256 ctLen = count;
        uint32 x = startX;
        space[0] = x;
        for(uint256 i = 1; i < ctLen;)
        {
            x = _runImpl(x, argsMem);
            space[i] = x;
            unchecked { ++i; }
        }
        return space;
    }

    /// @dev Sparse evaluator. `opOffsets` MUST be sorted in non-decreasing
    /// order. Output length equals opOffsets.length, but the internal
    /// iteration depth is `opOffsets[last]` rather than allocating a full
    /// space array. Concrete transformations with closed-form semantics
    /// may override this with O(K) evaluation where K = opOffsets.length.
    function runAt(uint32 startX, uint32 /*startOp*/, uint32[] calldata opOffsets, uint32[] calldata args)
        external view virtual returns (uint32[] memory)
    {
        require(args.length == _argc, "wrong number of arguments");

        uint256 length = opOffsets.length;
        uint32[] memory out = new uint32[](length);
        if(length == 0)
        {
            return out;
        }

        uint32[] memory argsMem = args;
        uint256 maxOffset = uint256(opOffsets[length - 1]);
        uint32 x = startX;
        uint256 nextOutIndex = 0;

        // Emit any prefix of zero-offset entries before stepping.
        while(nextOutIndex < length && opOffsets[nextOutIndex] == 0)
        {
            out[nextOutIndex] = x;
            unchecked { ++nextOutIndex; }
        }

        for(uint256 step = 1; step <= maxOffset && nextOutIndex < length;)
        {
            x = _runImpl(x, argsMem);
            // Inner while preserves duplicate-offset semantics: multiple
            // requested offsets at the same step all receive `x`.
            while(nextOutIndex < length && opOffsets[nextOutIndex] == step)
            {
                out[nextOutIndex] = x;
                unchecked { ++nextOutIndex; }
            }
            unchecked { ++step; }
        }
        return out;
    }
}
