// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "../transformation/ITransformation.sol";
import "../condition/ICondition.sol";
import "../connector/IConnector.sol";

interface IRegistry
{
    enum EntityKind { Connector, Transformation, Condition }

    function protocolId() external pure returns (bytes32);
    function protocolVersion() external pure returns (uint64);

    /// @notice Everything an owner signs to authorize one publication. The EIP-712
    /// domain binds the chain id and this registry's address, so a signature cannot
    /// be replayed onto another chain or another registry.
    struct Publication {
        EntityKind kind;
        string name;
        address owner;
        bytes32 contentHash;
        bytes32 metadataHash;
        bytes32 creationCodeHash;
        bytes32 runtimeCodeHash;
        // keccak256(abi.encode(registration)) for a connector, zero otherwise, so the
        // arrays ConnectorAdded carries are the ones the owner authorized.
        bytes32 registrationHash;
        uint256 nonce;
        uint256 deadline;
    }

    /// @notice Connector shape carried into ConnectorAdded so a full connector record
    /// is reconstructable from chain logs alone. The owner authorizes it through
    /// Publication.registrationHash; the registry checks the dimension count and scalar
    /// shape against the deployed connector, and indexers check the rest against the
    /// connector's artifact.
    struct ConnectorRegistration {
        uint32 dimensionsCount;
        uint32[] compositeDimIds;
        string[] compositeNames;
        uint32[] bindingDimIds;
        uint32[] bindingSlotIds;
        string[] bindingNames;
        string conditionName;
        int32[] conditionArgs;
        // Static running instances (parallel arrays keyed by local position id).
        uint32[] staticRiPositions;
        uint32[] staticRiStartPoints;
        uint32[] staticRiTransformShifts;
        // Per-dimension transformation definitions (parallel arrays ordered by
        // (dimId, indexWithinDim)). transformationArgs is a single flattened array
        // consumed left-to-right by transformationArgCounts.
        uint32[] transformationDimIds;
        string[] transformationNames;
        uint32[] transformationArgCounts;
        int32[]  transformationArgs;
    }

    event TransformationAdded(
        address caller,
        string name,
        address transformationAddr,
        address owner,
        uint32 argsCount,
        bytes32 contentHash,
        bytes32 metadataHash,
        bytes32 runtimeCodeHash
    );

    event ConditionAdded(
        address caller,
        string name,
        address conditionAddr,
        address owner,
        uint32 argsCount,
        bytes32 contentHash,
        bytes32 metadataHash,
        bytes32 runtimeCodeHash
    );

    event ConnectorAdded(
        address indexed caller,
        address indexed owner,
        string name,
        address connectorAddr,
        uint32 dimensionsCount,
        uint32[] compositeDimIds,
        string[] compositeNames,
        uint32[] bindingDimIds,
        uint32[] bindingSlotIds,
        string[] bindingNames,
        string conditionName,
        int32[] conditionArgs,
        bytes32 formatHash,
        uint32[] staticRiPositions,
        uint32[] staticRiStartPoints,
        uint32[] staticRiTransformShifts,
        uint32[] transformationDimIds,
        string[] transformationNames,
        uint32[] transformationArgCounts,
        int32[] transformationArgs,
        bytes32 contentHash,
        bytes32 metadataHash,
        bytes32 runtimeCodeHash
    );

    event TransformationRemoved(address caller, address owner, string name, address entityAddr, bytes32 contentHash, bytes32 metadataHash);
    event ConditionRemoved(address caller, address owner, string name, address entityAddr, bytes32 contentHash, bytes32 metadataHash);
    event ConnectorRemoved(address caller, address owner, string name, address entityAddr, bytes32 contentHash, bytes32 metadataHash);
    event EntityOwnerChanged(EntityKind kind, string name, address entityAddr, address oldOwner, address newOwner);

    /// @notice Deploy `creationCode` with CREATE2, validate the deployed runtime and its
    /// PT identity against `publication`, then register it and emit the typed event.
    /// An empty `ownerSignature` is accepted only when msg.sender is the publication owner.
    /// The CREATE2 salt is keccak256(abi.encode(registry, kind, keccak256(name), owner,
    /// contentHash, nonce)), so the entity address is known before the transaction.
    function publishTransformation(
        bytes calldata creationCode,
        Publication calldata publication,
        bytes calldata ownerSignature
    ) external returns (address);

    function publishCondition(
        bytes calldata creationCode,
        Publication calldata publication,
        bytes calldata ownerSignature
    ) external returns (address);

    function publishConnector(
        bytes calldata creationCode,
        Publication calldata publication,
        ConnectorRegistration calldata registration,
        bytes calldata ownerSignature
    ) external returns (address);

    function publicationNonce(address owner) external view returns (uint256);
    function publicationDigest(Publication calldata publication) external view returns (bytes32);

    function getTransformation(string calldata name) external view returns (ITransformation);
    function getCondition(string calldata name) external view returns (ICondition);
    function getConnector(string calldata name) external view returns (IConnector);

    function getEntityOwner(EntityKind kind, string calldata name) external view returns (address);
    function getEntityContentHash(EntityKind kind, string calldata name) external view returns (bytes32);
    function getEntityMetadataHash(EntityKind kind, string calldata name) external view returns (bytes32);

    function clearTransformation(string calldata name) external;
    function clearCondition(string calldata name) external;
    function clearConnector(string calldata name) external;
    function changeEntityOwner(EntityKind kind, string calldata name, address newOwner) external;

    function containsTransformation(string calldata name) external view returns (bool);
    function containsCondition(string calldata name) external view returns (bool);
    function containsConnector(string calldata name) external view returns (bool);

    function formatConnectorsCount(bytes32 formatHash) external view returns (uint256);
    function getFormatConnector(bytes32 formatHash, uint256 index) external view returns (IConnector);

    function transformationsCount() external view returns (uint);
    function conditionsCount() external view returns (uint);
    function connectorsCount() external view returns (uint);
}
