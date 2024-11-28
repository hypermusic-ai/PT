// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../concept/IConcept.sol";
import "../operand/IOperand.sol";

interface IRegistry
{
    event Fallback(address caller,  string message);
    event ConceptAdded(address caller, string name, address conceptAddr);
    event OperandAdded(address caller, string name, address operandAddr);
    event ConceptRemoved(address caller, string name);
    event OperandRemoved(address caller, string name);

    function registerConcept(string calldata name, IConcept concept) external;
    function registerOperand(string calldata name, IOperand operand) external;

    function conceptAt(string calldata name) external view returns (IConcept);
    function operandAt(string calldata name) external view returns (IOperand);

    function clearConcept(string calldata name) external;
    function clearOperand(string calldata name) external;

    function containsConcept(string calldata name) external view returns (bool);
    function containsOperand(string calldata name) external view returns (bool);

    function conceptsCount() external view returns (uint);
    function operandsCount() external view returns (uint);
}