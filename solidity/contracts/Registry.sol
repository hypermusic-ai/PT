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

contract Registry is IRegistry
{
    mapping(string => address) private _concepts;
    mapping(string => address) private _operands;

    uint256 private _conceptsCount;
    uint256 private _operandsCount;

    // This function is executed on a call to the contract if none of the other
    // functions match the given function signature, or if no data is supplied at all
    fallback() external {
        emit Fallback(msg.sender, "Fallback was called");
    }

    function registerConcept(string calldata name, address conceptAddr) external {
        require(!this.containsConcept(name), string.concat(name, " concept of this name already registered"));
        _concepts[name] = conceptAddr;
        _conceptsCount++;
        emit ConceptAdded(msg.sender, name, _concepts[name]);
    }

    function registerOperand(string calldata name, address operandAddr) external {
        require(!this.containsOperand(name), string.concat(name, " operand of this name already registered"));
        _operands[name] = operandAddr;
        _operandsCount++;
        emit OperandAdded(msg.sender, name, _operands[name]);
    }

    function conceptAt(string calldata name) external view returns (address)
    {
        return _concepts[name];
    }

    function operandAt(string calldata name) external view returns (address)
    {
        return _operands[name];
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