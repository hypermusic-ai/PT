// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

interface IPTInitializable
{
    function initialize() external;
}

/// ERC-1967 proxy of an upgradeable PT contract, the registry or the runner. It initializes
/// the implementation in its constructor, so the deployer becomes the upgrade owner.
contract PTContractProxy is ERC1967Proxy
{
    constructor(address implementation)
        ERC1967Proxy(implementation, abi.encodeCall(IPTInitializable.initialize, ()))
    {}
}
