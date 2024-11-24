// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Concept.sol";
import "./Operand.sol";

contract Registry
{
    mapping(string => address) private _concepts;
    mapping(string => address) private _operands;

    uint256 private _conceptsCount;
    uint256 private _operandsCount;

    event Received(address caller,  string message);

    event ConceptAdded(address caller, string name, address conceptAddr);
    event OperandAdded(address caller, string name, address operandAddr);
    event ConceptRemoved(address caller, string name);
    event OperandRemoved(address caller, string name);

    // This function is executed on a call to the contract if none of the other
    // functions match the given function signature, or if no data is supplied at all
    fallback() external {
        emit Received(msg.sender, "Fallback was called");
    }

    function registerConcept(string calldata name, Concept instance) external {
        require(!this.containsConcept(name), string.concat(name, " concept of this name already registered"));
        _concepts[name] = address(instance);
        _conceptsCount++;
        emit ConceptAdded(msg.sender, name, _concepts[name]);
    }

    function registerOperand(string calldata name, Operand instance) external {
        require(!this.containsOperand(name), string.concat(name, " operand of this name already registered"));
        _operands[name] = address(instance);
        _operandsCount++;
        emit OperandAdded(msg.sender, name, _operands[name]);
    }

    function conceptAt(string calldata name) external view returns (Concept)
    {
        return Concept(_concepts[name]);
    }

    function operandAt(string calldata name) external view returns (Operand)
    {
        return Operand(_operands[name]);
    }

    function clearConcept(string calldata name) external {
        require(this.containsConcept(name), "Concept does not exist");
        _concepts[name] = address(0);
        _conceptsCount--;
        emit ConceptRemoved(msg.sender, name);
    }

    function clearOperand(string calldata name) external {
        require(this.containsOperand(name), "Operand does not exist");
        _operands[name] = address(0);
        _operandsCount--;
        emit OperandRemoved(msg.sender, name);
    }

    function containsConcept(string calldata name) external view returns (bool)
    {
        return _concepts[name] != address(0);
    }

    function containsOperand(string calldata name) external view returns (bool)
    {
        return _operands[name] != address(0);
    }

    function conceptsCount() external view returns (uint) {
        return _conceptsCount;
    }

    function operandsCount() external view returns (uint) {
        return _operandsCount;
    }
}