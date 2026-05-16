// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "../ownable/IOwnable.sol";

import "../condition/ICondition.sol";

interface IConnector is IOwnable
{
    function getName() external view returns(string memory);
    
    function getScalarsCount() external view returns (uint32);
    function getScalarHash(uint32 scalarId) external view returns (bytes32);
    function getFormatHash() external view returns (bytes32);
    function getOpenSlotsCount() external view returns (uint32);

    function getDimensionsCount() external view returns (uint32);
    function transform(uint32 dimId, uint32 txId, uint32 x) external view returns (uint32);

    /// @notice Batched contiguous evaluation: returns the iterated space
    /// [x_0, x_1, ..., x_{count-1}] where x_0 = startX and x_{i+1} is
    /// produced by applying the transformation chain at this dimension.
    /// `startOp` is the operation index of x_0 (transform shift base).
    function transformRange(uint32 dimId, uint32 startOp, uint32 startX, uint32 count)
        external view returns (uint32[] memory);

    /// @notice Batched sparse evaluation: returns the iterated value at
    /// each offset in `opOffsets` from `startX`. `opOffsets` must be
    /// sorted in non-decreasing order.
    function transformAt(uint32 dimId, uint32 startOp, uint32 startX, uint32[] calldata opOffsets)
        external view returns (uint32[] memory);

    function getCompositesCount() external view returns (uint32);
    function getComposite(uint32 dimId) external view returns (IConnector);
    function getBindingComposite(uint32 dimId, uint32 slotId) external view returns (IConnector);
    function getStaticRunningInstance(uint32 localPosId) external view returns (bool hasValue, uint32 startPoint, uint32 transformShift);

    function getCondition() external view returns (ICondition);
    function getConditionArgs() external view returns (int32[] memory);
    function checkCondition() external view returns(bool);
}
