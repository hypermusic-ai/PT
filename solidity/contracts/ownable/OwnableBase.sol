// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./IOwnable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

abstract contract OwnableBase is IOwnable, Initializable, UUPSUpgradeable
{
    address private _owner;

    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __OwnableBase_init(address owner_) internal onlyInitializing {
        _owner = owner_;
        emit OwnerSet(address(0), _owner);
    }

    function changeOwner(address newOwner) external isOwner {
        emit OwnerSet(_owner, newOwner);
        _owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }

    function _authorizeUpgrade(address) internal override isOwner {}
}
