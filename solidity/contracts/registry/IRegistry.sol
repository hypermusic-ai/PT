// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../concept/IConcept.sol";
import "../transformation/ITransformation.sol";

interface IRegistry
{
    event Fallback(address caller,  string message);
    event ConceptAdded(address caller, string name, address conceptAddr);
    event TransformationAdded(address caller, string name, address transformationAddr);
    event ConceptRemoved(address caller, string name);
    event TransformationRemoved(address caller, string name);

    function registerConcept(string calldata name, IConcept concept) external;
    function registerTransformation(string calldata name, ITransformation transformation) external;

    function conceptAt(string calldata name) external view returns (IConcept);
    function transformationAt(string calldata name) external view returns (ITransformation);

    function clearConcept(string calldata name) external;
    function clearTransformation(string calldata name) external;

    function containsConcept(string calldata name) external view returns (bool);
    function containsTransformation(string calldata name) external view returns (bool);

    function conceptsCount() external view returns (uint);
    function transformationsCount() external view returns (uint);
}