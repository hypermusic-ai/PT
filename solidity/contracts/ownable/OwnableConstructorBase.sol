// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./IOwnable.sol";

abstract contract OwnableConstructorBase is IOwnable
{
    address private _owner;

    modifier isOwner() {
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    constructor(address owner_) {
        require(owner_ != address(0), "owner is zero");
        _owner = owner_;
        emit OwnerSet(address(0), _owner);
    }

    function changeOwner(address newOwner) external isOwner {
        require(newOwner != address(0), "new owner is zero");
        emit OwnerSet(_owner, newOwner);
        _owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }
}
