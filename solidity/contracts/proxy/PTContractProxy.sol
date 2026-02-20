// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

interface IPTInitializable
{
    function initialize(address registryAddr) external;
}

contract PTContractProxy is ERC1967Proxy
{
    constructor(address implementation, address registryAddr)
        ERC1967Proxy(implementation, abi.encodeCall(IPTInitializable.initialize, (registryAddr)))
    {}
}
