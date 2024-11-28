// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IRegistry
{
    event Fallback(address caller,  string message);
    event ConceptAdded(address caller, string name, address conceptAddr);
    event OperandAdded(address caller, string name, address operandAddr);
    event ConceptRemoved(address caller, string name);
    event OperandRemoved(address caller, string name);

    function registerConcept(string calldata name, address conceptAddr) external;
    function registerOperand(string calldata name, address operandAddr) external;

    function conceptAt(string calldata name) external view returns (address);
    function operandAt(string calldata name) external view returns (address);

    function clearConcept(string calldata name) external;
    function clearOperand(string calldata name) external;

    function containsConcept(string calldata name) external view returns (bool);
    function containsOperand(string calldata name) external view returns (bool);

    function conceptsCount() external view returns (uint);
    function operandsCount() external view returns (uint);
}