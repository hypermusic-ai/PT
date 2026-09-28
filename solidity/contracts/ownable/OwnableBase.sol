// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./IOwnable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

abstract contract OwnableBase is IOwnable, Initializable, UUPSUpgradeable
{
    address private _owner;

    // Reserved so a variable added here later does not shift the storage of the
    // upgradeable contracts that inherit from this one.
    uint256[49] private __gap;

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
        _setOwner(owner_);
    }

    function changeOwner(address newOwner) external isOwner {
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        require(newOwner != address(0), "owner is zero");
        emit OwnerSet(_owner, newOwner);
        _owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }

    function _authorizeUpgrade(address) internal override isOwner {}
}
