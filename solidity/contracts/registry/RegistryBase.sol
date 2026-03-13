// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./IRegistry.sol";
import "../error/Error.sol";
import "../ownable/OwnableBase.sol";

contract RegistryBase is IRegistry, OwnableBase
{
    mapping(string => address) private _transformations;
    mapping(string => address) private _conditions;
    mapping(string => address) private _connectors;

    uint256 private _transformationsCount;
    uint256 private _conditionsCount;
    uint256 private _connectorsCount;

    function initialize() external initializer {
        __OwnableBase_init(msg.sender);
    }

    // This function is executed on a call to the contract if none of the other
    // functions match the given function signature, or if no data is supplied at all
    fallback() external {
        revert RegistryError(1);
    }

    function registerTransformation(
        string calldata name,
        ITransformation transformation,
        TransformationRegistration calldata registration
    ) external {
        if(_transformations[name] != address(0))
        {
            revert TransformationAlreadyRegistered(keccak256(bytes(name)));
        }

        _transformations[name] = address(transformation);
        _transformationsCount++;
        emit TransformationAdded(msg.sender, name, _transformations[name], registration.owner, registration.argsCount);
    }

    function registerCondition(
        string calldata name,
        ICondition condition,
        ConditionRegistration calldata registration
    ) external {
        if(_conditions[name] != address(0))
        {
            revert ConditionAlreadyRegistered(keccak256(bytes(name)));
        }

        _conditions[name] = address(condition);
        _conditionsCount++;
        emit ConditionAdded(msg.sender, name, _conditions[name], registration.owner, registration.argsCount);
    }

    function registerConnector(
        string calldata name,
        IConnector connector,
        ConnectorRegistration calldata registration
    ) external {
        if(_connectors[name] != address(0))
        {
            revert ConnectorAlreadyRegistered(keccak256(bytes(name)));
        }

        _connectors[name] = address(connector);
        _connectorsCount++;

        ConnectorRegistration memory emittedRegistration = registration;

        emit ConnectorAdded(
            msg.sender,
            emittedRegistration.owner,
            name,
            address(connector),
            emittedRegistration.dimensionsCount,
            emittedRegistration.compositeDimIds,
            emittedRegistration.compositeNames,
            emittedRegistration.bindingDimIds,
            emittedRegistration.bindingSlotIds,
            emittedRegistration.bindingNames,
            emittedRegistration.conditionName,
            emittedRegistration.conditionArgs
        );
    }

    function getTransformation(string calldata name) external view returns (ITransformation)
    {
        if(_transformations[name] == address(0))
        {
            revert TransformationMissing(keccak256(bytes(name)));
        }
        return ITransformation(_transformations[name]);
    }

    function getCondition(string calldata name) external view returns (ICondition)
    {
        if(_conditions[name] == address(0))
        {
            revert ConditionMissing(keccak256(bytes(name)));
        }
        return ICondition(_conditions[name]);
    }

    function getConnector(string calldata name) external view returns (IConnector)
    {
        if(_connectors[name] == address(0))
        {
            revert ConnectorMissing(keccak256(bytes(name)));
        }
        return IConnector(_connectors[name]);
    }

    function clearTransformation(string calldata name) external {
        if(_transformations[name] == address(0))
        {
            revert TransformationMissing(keccak256(bytes(name)));
        }
        _transformations[name] = address(0);
        assert(_transformationsCount > 0);
        _transformationsCount--;
        emit TransformationRemoved(msg.sender, name);
    }

    function clearCondition(string calldata name) external {
        if(_conditions[name] == address(0))
        {
            revert ConditionMissing(keccak256(bytes(name)));
        }
        _conditions[name] = address(0);
        assert(_conditionsCount > 0);
        _conditionsCount--;
        emit ConditionRemoved(msg.sender, name);
    }

    function clearConnector(string calldata name) external {
        if(_connectors[name] == address(0))
        {
            revert ConnectorMissing(keccak256(bytes(name)));
        }
        _connectors[name] = address(0);
        assert(_connectorsCount > 0);
        _connectorsCount--;
        emit ConnectorRemoved(msg.sender, name);
    }

    function containsTransformation(string calldata name) external view returns (bool)
    {
        return _transformations[name] != address(0);
    }

    function containsCondition(string calldata name) external view returns (bool)
    {
        return _conditions[name] != address(0);
    }

    function containsConnector(string calldata name) external view returns (bool)
    {
        return _connectors[name] != address(0);
    }

    function transformationsCount() external view returns (uint) {
        return _transformationsCount;
    }

    function conditionsCount() external view returns (uint) {
        return _conditionsCount;
    }

    function connectorsCount() external view returns (uint) {
        return _connectorsCount;
    }
}
