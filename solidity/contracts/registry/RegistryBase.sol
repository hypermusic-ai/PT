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
    mapping(string => bytes32) private _connectorFormatHashes;

    mapping(bytes32 => address[]) private _formatConnectors;

    // it gives O(1) “already present?” check, so the same connector address is not pushed twice for one format
    // it enables O(1) removal via swap-and-pop and updates the moved element index
    // indexPlusOne is used because Solidity mapping default is 0, so:
    // 0 = “not present”
    // 1..N = real array index + 1
    mapping(bytes32 => mapping(address => uint256)) private _formatConnectorIndexPlusOne;
    // Number of registered names per (formatHash, connector address).
    // The address stays in _formatConnectors[formatHash] while refCount > 0.
    mapping(bytes32 => mapping(address => uint256)) private _formatConnectorRefCount;

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

    function _addConnectorToFormat(bytes32 formatHash, address connectorAddr) private
    {
        uint256 refCount = _formatConnectorRefCount[formatHash][connectorAddr];
        if(refCount == 0)
        {
            _formatConnectors[formatHash].push(connectorAddr);
            _formatConnectorIndexPlusOne[formatHash][connectorAddr] = _formatConnectors[formatHash].length;
        }

        _formatConnectorRefCount[formatHash][connectorAddr] = refCount + 1;
    }

    function _removeConnectorFromFormat(bytes32 formatHash, address connectorAddr) private
    {
        uint256 refCount = _formatConnectorRefCount[formatHash][connectorAddr];
        if(refCount == 0)
        {
            return;
        }

        if(refCount > 1)
        {
            _formatConnectorRefCount[formatHash][connectorAddr] = refCount - 1;
            return;
        }

        uint256 indexPlusOne = _formatConnectorIndexPlusOne[formatHash][connectorAddr];
        assert(indexPlusOne != 0);

        address[] storage connectors = _formatConnectors[formatHash];
        uint256 index = indexPlusOne - 1;
        uint256 lastIndex = connectors.length - 1;

        if(index != lastIndex)
        {
            address moved = connectors[lastIndex];
            connectors[index] = moved;
            _formatConnectorIndexPlusOne[formatHash][moved] = index + 1;
        }

        connectors.pop();
        delete _formatConnectorRefCount[formatHash][connectorAddr];
        delete _formatConnectorIndexPlusOne[formatHash][connectorAddr];
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

        require(msg.sender == address(transformation), "caller must be transformation");

        // TransformationBase self-registers from constructor.
        // During construction, code length at `transformation` is zero and
        // getter calls would revert. Enforce getter-based checks only after deployment.
        if(address(transformation).code.length != 0)
        {
            require(
                registration.argsCount == transformation.getArgsCount(),
                "transformation args count mismatch");
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

        require(msg.sender == address(condition), "caller must be condition");

        // ConditionBase self-registers from constructor.
        // During construction, code length at `condition` is zero and
        // getter calls would revert. Enforce getter-based checks only after deployment.
        if(address(condition).code.length != 0)
        {
            require(
                keccak256(bytes(name)) == keccak256(bytes(condition.getName())),
                "condition name mismatch");
            require(
                registration.argsCount == condition.getArgsCount(),
                "condition args count mismatch");
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

        require(msg.sender == address(connector), "caller must be connector");

        // ConnectorBase self-registers from constructor.
        // During construction, code length at `connector` is zero and
        // getter calls would revert. Enforce getter-based checks only after deployment.
        if(address(connector).code.length != 0)
        {
            require(
                keccak256(bytes(name)) == keccak256(bytes(connector.getName())),
                "connector name mismatch");
            require(
                registration.formatHash == connector.getFormatHash(),
                "connector format hash mismatch");

            uint32 scalarsCount = connector.getScalarsCount();
            require(scalarsCount > 0, "connector has zero scalars");
            require(
                scalarsCount == connector.getOpenSlotsCount(),
                "connector scalars/open slots mismatch");

            // Interface sanity check for merged scalar-label hashing.
            connector.getScalarHash(0);
        }

        _connectors[name] = address(connector);
        _connectorsCount++;

        bytes32 formatHash = registration.formatHash;
        _connectorFormatHashes[name] = formatHash;
        _addConnectorToFormat(formatHash, address(connector));

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
            emittedRegistration.conditionArgs,
            emittedRegistration.formatHash,
            emittedRegistration.staticRiPositions,
            emittedRegistration.staticRiStartPoints,
            emittedRegistration.staticRiTransformShifts,
            emittedRegistration.transformationDimIds,
            emittedRegistration.transformationNames,
            emittedRegistration.transformationArgCounts,
            emittedRegistration.transformationArgs
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

        address connectorAddr = _connectors[name];
        bytes32 formatHash = _connectorFormatHashes[name];

        _removeConnectorFromFormat(formatHash, connectorAddr);

        _connectors[name] = address(0);
        delete _connectorFormatHashes[name];
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

    function formatConnectorsCount(bytes32 formatHash) external view returns (uint256)
    {
        return _formatConnectors[formatHash].length;
    }

    function getFormatConnector(bytes32 formatHash, uint256 index) external view returns (IConnector)
    {
        require(index < _formatConnectors[formatHash].length, "format index out of range");
        return IConnector(_formatConnectors[formatHash][index]);
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
