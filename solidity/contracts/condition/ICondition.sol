// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "../ownable/IOwnable.sol";

interface ICondition is IOwnable
{
    function update() external;
    function check() external view returns(bool);
}