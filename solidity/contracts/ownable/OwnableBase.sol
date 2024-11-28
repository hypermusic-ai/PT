// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "contracts/ownable/IOwnable.sol";

contract OwnableBase is IOwnable
{
    address private _owner;

    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnerSet(address(0), _owner);
    }

    function changeOwner(address newOwner) external isOwner {
        emit OwnerSet(_owner, newOwner);
        _owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }
} 