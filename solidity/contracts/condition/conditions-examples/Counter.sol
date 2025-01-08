// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../ConditionBase.sol";

contract Counter is ConditionBase
{
    uint32 private _counts;

    constructor(uint32 counts)
    {
        _counts = counts;
    }

    function update() override virtual external
    {
        assert(_counts > 0);
        _counts--;
    }

    function check() override external view returns(bool)
    {
        return _counts > 0;
    }
}