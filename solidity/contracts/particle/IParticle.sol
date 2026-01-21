// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "../ownable/IOwnable.sol";

import "../feature/IFeature.sol";

interface IParticle is IOwnable
{
    function getName() external view returns(string memory);
    
    function getScalarsCount() external view returns (uint32);

    function getRootFeature() external view returns (IFeature);

    function getCompositesCount() external view returns (uint32);
    function getComposite(uint32 dimId) external view returns (address);

    function checkCondition() external view returns(bool);
}