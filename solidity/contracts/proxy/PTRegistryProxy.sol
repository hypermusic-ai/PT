// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

interface IRegistryInitializable
{
    function initialize() external;
}

contract PTRegistryProxy is ERC1967Proxy
{
    constructor(address implementation)
        ERC1967Proxy(implementation, abi.encodeCall(IRegistryInitializable.initialize, ()))
    {}
}
