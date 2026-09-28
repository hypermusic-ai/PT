// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import "./ICondition.sol";
import "../entity/PTEntity.sol";

abstract contract ConditionBase is ICondition, PTEntityBase
{
    uint32 private _argc;

    constructor(string memory name, uint32 argc, bytes32 contentHash_, bytes32 metadataHash_)
        PTEntityBase(name, contentHash_, metadataHash_)
    {
        _argc = argc;
    }

    function ptKind() external pure virtual override returns (uint8)
    {
        return PTEntityKind.CONDITION;
    }

    function getArgsCount() external view returns(uint32)
    {
        return _argc;
    }
}
