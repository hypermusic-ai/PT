// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "../ownable/IOwnable.sol";

interface IFeature is IOwnable
{
    function getName() external view returns(string memory);
    function getDimensionsCount() external view returns (uint32);
    function transform(uint32 dimId, uint32 txId, uint32 x) external view returns (uint32);
}