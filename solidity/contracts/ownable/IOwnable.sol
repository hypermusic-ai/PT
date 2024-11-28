// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IOwnable
{
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    function getOwner() external view returns (address);

    function changeOwner(address newOwner) external;
}