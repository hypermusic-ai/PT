// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./IRegistry.sol";
import "../error/Error.sol";
import "../entity/PTEntity.sol";
import "../ownable/OwnableBase.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @dev ReentrancyGuard's constructor only initializes the implementation's storage; a
/// proxy starts with a zero status, which the guard also reads as "not entered".
contract RegistryBase is IRegistry, OwnableBase, ReentrancyGuard
{
    bytes32 private constant _PROTOCOL_ID = keccak256("hypermusic.pt");
    uint64 private constant _PROTOCOL_VERSION = 1;

    bytes32 private constant _EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 private constant _PUBLICATION_TYPEHASH = keccak256(
        "Publication(uint8 kind,string name,address owner,bytes32 contentHash,bytes32 metadataHash,"
        "bytes32 creationCodeHash,bytes32 runtimeCodeHash,bytes32 registrationHash,uint256 nonce,uint256 deadline)");

    mapping(string => address) private _transformations;
    mapping(string => address) private _conditions;
    mapping(string => address) private _connectors;
    mapping(string => bytes32) private _connectorFormatHashes;

    mapping(uint8 => mapping(string => address)) private _entityOwners;
    mapping(uint8 => mapping(string => bytes32)) private _entityContentHashes;
    mapping(uint8 => mapping(string => bytes32)) private _entityMetadataHashes;

    // Consumed once per authenticated publication so a captured signature cannot be replayed.
    mapping(address => uint256) private _publicationNonces;

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

    function protocolId() external pure returns (bytes32)
    {
        return _PROTOCOL_ID;
    }

    function protocolVersion() external pure returns (uint64)
    {
        return _PROTOCOL_VERSION;
    }

    // This function is executed on a call to the contract if none of the other
    // functions match the given function signature, or if no data is supplied at all
    fallback() external {
        revert RegistryError(1);
    }

    // ---------------------------------------------------------------------
    // Publication authentication
    // ---------------------------------------------------------------------

    function publicationNonce(address owner) external view returns (uint256)
    {
        return _publicationNonces[owner];
    }

    function publicationDigest(Publication calldata publication) public view returns (bytes32)
    {
        bytes32 domainSeparator = keccak256(abi.encode(
            _EIP712_DOMAIN_TYPEHASH,
            keccak256("PT"),
            keccak256("1"),
            block.chainid,
            address(this)));

        bytes32 structHash = keccak256(abi.encode(
            _PUBLICATION_TYPEHASH,
            uint8(publication.kind),
            keccak256(bytes(publication.name)),
            publication.owner,
            publication.contentHash,
            publication.metadataHash,
            publication.creationCodeHash,
            publication.runtimeCodeHash,
            publication.registrationHash,
            publication.nonce,
            publication.deadline));

        return keccak256(abi.encodePacked(hex"1901", domainSeparator, structHash));
    }

    function _authorizePublication(
        EntityKind kind,
        Publication calldata publication,
        bytes32 registrationHash,
        bytes calldata ownerSignature
    ) private
    {
        require(publication.kind == kind, "publication kind mismatch");
        require(publication.registrationHash == registrationHash, "registration hash mismatch");
        require(publication.owner != address(0), "owner is zero");
        require(bytes(publication.name).length != 0, "name is empty");
        require(publication.contentHash != bytes32(0), "content hash is zero");
        require(publication.metadataHash != bytes32(0), "metadata hash is zero");
        require(block.timestamp <= publication.deadline, "publication expired");
        require(publication.nonce == _publicationNonces[publication.owner], "publication nonce mismatch");

        if(ownerSignature.length == 0)
        {
            require(msg.sender == publication.owner, "caller is not publication owner");
        }
        else
        {
            require(
                ECDSA.recover(publicationDigest(publication), ownerSignature) == publication.owner,
                "invalid owner signature");
        }

        _publicationNonces[publication.owner] = publication.nonce + 1;
    }

    /// @dev Deploys the entity and proves that the deployed runtime is the one the owner
    /// signed for. Nothing here trusts the constructor: every check runs after CREATE2
    /// returns, when the runtime code exists and the getters are callable. The nonce in
    /// the salt lets a cleared name be published again with the same content.
    function _deployEntity(
        bytes calldata creationCode,
        Publication calldata publication
    ) private returns (address entityAddr)
    {
        require(creationCode.length != 0, "creation code is empty");
        require(keccak256(creationCode) == publication.creationCodeHash, "creation code hash mismatch");

        bytes32 salt = keccak256(abi.encode(
            address(this),
            uint8(publication.kind),
            keccak256(bytes(publication.name)),
            publication.owner,
            publication.contentHash,
            publication.nonce));

        bytes memory code = creationCode;
        // Reads only the bytes Solidity allocated for `code`, which lets the via-IR
        // pipeline move stack variables to memory where the ABI encoder needs it.
        assembly ("memory-safe") {
            entityAddr := create2(0, add(code, 0x20), mload(code), salt)
        }

        require(entityAddr != address(0), "entity deployment failed");
        require(entityAddr.code.length != 0, "entity has no runtime code");
        require(entityAddr.codehash == publication.runtimeCodeHash, "runtime code hash mismatch");

        IPTEntity entity = IPTEntity(entityAddr);
        require(entity.ptKind() == uint8(publication.kind), "entity kind mismatch");
        require(entity.ptVersion() == _PROTOCOL_VERSION, "entity protocol version mismatch");
        require(
            keccak256(bytes(entity.getName())) == keccak256(bytes(publication.name)),
            "entity name mismatch");
        require(entity.contentHash() == publication.contentHash, "entity content hash mismatch");
        require(entity.metadataHash() == publication.metadataHash, "entity metadata hash mismatch");
    }

    function _recordEntity(Publication calldata publication) private
    {
        uint8 kindId = uint8(publication.kind);
        _entityOwners[kindId][publication.name] = publication.owner;
        _entityContentHashes[kindId][publication.name] = publication.contentHash;
        _entityMetadataHashes[kindId][publication.name] = publication.metadataHash;
    }

    function _forgetEntity(EntityKind kind, string calldata name) private
    {
        uint8 kindId = uint8(kind);
        delete _entityOwners[kindId][name];
        delete _entityContentHashes[kindId][name];
        delete _entityMetadataHashes[kindId][name];
    }

    function _requireEntityOwner(EntityKind kind, string calldata name) private view returns (address entityOwner)
    {
        entityOwner = _entityOwners[uint8(kind)][name];
        require(msg.sender == entityOwner, "caller is not entity owner");
    }

    // ---------------------------------------------------------------------
    // Format index
    // ---------------------------------------------------------------------

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

    // ---------------------------------------------------------------------
    // Publication
    // ---------------------------------------------------------------------

    function publishTransformation(
        bytes calldata creationCode,
        Publication calldata publication,
        bytes calldata ownerSignature
    ) external nonReentrant returns (address)
    {
        if(_transformations[publication.name] != address(0))
        {
            revert TransformationAlreadyRegistered(keccak256(bytes(publication.name)));
        }

        _authorizePublication(EntityKind.Transformation, publication, bytes32(0), ownerSignature);

        address entityAddr = _deployEntity(creationCode, publication);
        uint32 argsCount = ITransformation(entityAddr).getArgsCount();

        _transformations[publication.name] = entityAddr;
        _recordEntity(publication);
        _transformationsCount++;

        emit TransformationAdded(
            msg.sender,
            publication.name,
            entityAddr,
            publication.owner,
            argsCount,
            publication.contentHash,
            publication.metadataHash,
            publication.runtimeCodeHash);

        return entityAddr;
    }

    function publishCondition(
        bytes calldata creationCode,
        Publication calldata publication,
        bytes calldata ownerSignature
    ) external nonReentrant returns (address)
    {
        if(_conditions[publication.name] != address(0))
        {
            revert ConditionAlreadyRegistered(keccak256(bytes(publication.name)));
        }

        _authorizePublication(EntityKind.Condition, publication, bytes32(0), ownerSignature);

        address entityAddr = _deployEntity(creationCode, publication);
        uint32 argsCount = ICondition(entityAddr).getArgsCount();

        _conditions[publication.name] = entityAddr;
        _recordEntity(publication);
        _conditionsCount++;

        emit ConditionAdded(
            msg.sender,
            publication.name,
            entityAddr,
            publication.owner,
            argsCount,
            publication.contentHash,
            publication.metadataHash,
            publication.runtimeCodeHash);

        return entityAddr;
    }

    function publishConnector(
        bytes calldata creationCode,
        Publication calldata publication,
        ConnectorRegistration calldata registration,
        bytes calldata ownerSignature
    ) external nonReentrant returns (address)
    {
        if(_connectors[publication.name] != address(0))
        {
            revert ConnectorAlreadyRegistered(keccak256(bytes(publication.name)));
        }

        _authorizePublication(
            EntityKind.Connector, publication, keccak256(abi.encode(registration)), ownerSignature);

        address entityAddr = _deployEntity(creationCode, publication);
        _validateConnectorRegistration(entityAddr, registration);

        // The format hash is derived state, so it is read back from the deployed
        // connector rather than trusted from the publisher.
        bytes32 formatHash = IConnector(entityAddr).getFormatHash();

        _connectors[publication.name] = entityAddr;
        _connectorFormatHashes[publication.name] = formatHash;
        _addConnectorToFormat(formatHash, entityAddr);
        _recordEntity(publication);
        _connectorsCount++;

        _emitConnectorAdded(entityAddr, formatHash, publication, registration);

        return entityAddr;
    }

    function _validateConnectorRegistration(
        address entityAddr,
        ConnectorRegistration calldata registration
    ) private view
    {
        IConnector connector = IConnector(entityAddr);

        // The registry address is a constructor argument, so it is not part of the runtime
        // code hash: a connector built against another registry would resolve different
        // dependencies than the ones its event names.
        require(connector.registry() == address(this), "connector is bound to another registry");
        require(registration.dimensionsCount == connector.getDimensionsCount(), "connector dimensions mismatch");

        uint32 scalarsCount = connector.getScalarsCount();
        require(scalarsCount > 0, "connector has zero scalars");
        require(scalarsCount == connector.getOpenSlotsCount(), "connector scalars/open slots mismatch");

        // Interface sanity check for merged scalar-label hashing.
        connector.getScalarHash(0);
    }

    function _emitConnectorAdded(
        address entityAddr,
        bytes32 formatHash,
        Publication calldata publication,
        ConnectorRegistration calldata registration
    ) private
    {
        emit ConnectorAdded(
            msg.sender,
            publication.owner,
            publication.name,
            entityAddr,
            registration.dimensionsCount,
            registration.compositeDimIds,
            registration.compositeNames,
            registration.bindingDimIds,
            registration.bindingSlotIds,
            registration.bindingNames,
            registration.conditionName,
            registration.conditionArgs,
            formatHash,
            registration.staticRiPositions,
            registration.staticRiStartPoints,
            registration.staticRiTransformShifts,
            registration.transformationDimIds,
            registration.transformationNames,
            registration.transformationArgCounts,
            registration.transformationArgs,
            publication.contentHash,
            publication.metadataHash,
            publication.runtimeCodeHash);
    }

    // ---------------------------------------------------------------------
    // Lookup
    // ---------------------------------------------------------------------

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

    function getEntityOwner(EntityKind kind, string calldata name) external view returns (address)
    {
        return _entityOwners[uint8(kind)][name];
    }

    function getEntityContentHash(EntityKind kind, string calldata name) external view returns (bytes32)
    {
        return _entityContentHashes[uint8(kind)][name];
    }

    function getEntityMetadataHash(EntityKind kind, string calldata name) external view returns (bytes32)
    {
        return _entityMetadataHashes[uint8(kind)][name];
    }

    // ---------------------------------------------------------------------
    // Removal and ownership
    // ---------------------------------------------------------------------

    function clearTransformation(string calldata name) external {
        address entityAddr = _transformations[name];
        if(entityAddr == address(0))
        {
            revert TransformationMissing(keccak256(bytes(name)));
        }

        address entityOwner = _requireEntityOwner(EntityKind.Transformation, name);
        bytes32 entityContentHash = _entityContentHashes[uint8(EntityKind.Transformation)][name];
        bytes32 entityMetadataHash = _entityMetadataHashes[uint8(EntityKind.Transformation)][name];

        delete _transformations[name];
        _forgetEntity(EntityKind.Transformation, name);
        assert(_transformationsCount > 0);
        _transformationsCount--;

        emit TransformationRemoved(msg.sender, entityOwner, name, entityAddr, entityContentHash, entityMetadataHash);
    }

    function clearCondition(string calldata name) external {
        address entityAddr = _conditions[name];
        if(entityAddr == address(0))
        {
            revert ConditionMissing(keccak256(bytes(name)));
        }

        address entityOwner = _requireEntityOwner(EntityKind.Condition, name);
        bytes32 entityContentHash = _entityContentHashes[uint8(EntityKind.Condition)][name];
        bytes32 entityMetadataHash = _entityMetadataHashes[uint8(EntityKind.Condition)][name];

        delete _conditions[name];
        _forgetEntity(EntityKind.Condition, name);
        assert(_conditionsCount > 0);
        _conditionsCount--;

        emit ConditionRemoved(msg.sender, entityOwner, name, entityAddr, entityContentHash, entityMetadataHash);
    }

    function clearConnector(string calldata name) external {
        address connectorAddr = _connectors[name];
        if(connectorAddr == address(0))
        {
            revert ConnectorMissing(keccak256(bytes(name)));
        }

        address entityOwner = _requireEntityOwner(EntityKind.Connector, name);
        bytes32 entityContentHash = _entityContentHashes[uint8(EntityKind.Connector)][name];
        bytes32 entityMetadataHash = _entityMetadataHashes[uint8(EntityKind.Connector)][name];
        bytes32 formatHash = _connectorFormatHashes[name];

        _removeConnectorFromFormat(formatHash, connectorAddr);

        delete _connectors[name];
        delete _connectorFormatHashes[name];
        _forgetEntity(EntityKind.Connector, name);
        assert(_connectorsCount > 0);
        _connectorsCount--;

        emit ConnectorRemoved(msg.sender, entityOwner, name, connectorAddr, entityContentHash, entityMetadataHash);
    }

    function changeEntityOwner(EntityKind kind, string calldata name, address newOwner) external {
        require(newOwner != address(0), "new owner is zero");

        address oldOwner = _entityOwners[uint8(kind)][name];
        require(oldOwner != address(0), "entity missing");
        require(msg.sender == oldOwner, "caller is not entity owner");

        address entityAddr = kind == EntityKind.Connector
            ? _connectors[name]
            : kind == EntityKind.Transformation
                ? _transformations[name]
                : _conditions[name];
        require(entityAddr != address(0), "entity missing");

        _entityOwners[uint8(kind)][name] = newOwner;
        emit EntityOwnerChanged(kind, name, entityAddr, oldOwner, newOwner);
    }

    // ---------------------------------------------------------------------
    // Membership and counts
    // ---------------------------------------------------------------------

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
