// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "../ownable/IOwnable.sol";

import "../feature/IFeature.sol";

import "../condition/ICondition.sol";

interface IConnector is IOwnable
{
    function getName() external view returns(string memory);
    
    function getScalarsCount() external view returns (uint32);

    function getRootFeature() external view returns (IFeature);
    function getCompositesCount() external view returns (uint32);
    function getComposite(uint32 dimId) external view returns (IConnector);

    function getCondition() external view returns (ICondition);
    function getConditionArgs() external view returns (int32[] memory);
    function checkCondition() external view returns(bool);
}