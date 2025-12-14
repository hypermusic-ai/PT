// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "../ownable/IOwnable.sol";

interface ICondition is IOwnable
{
    /// @notice Get number of arguments for condition
    function getArgsCount() external view returns(uint32);

    /// @notice Checks condition.
    ///
    /// @param args Array containing arguments for this condition.
    function check(int32[] calldata args) external view returns (bool);
}